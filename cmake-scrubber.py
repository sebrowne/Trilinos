import os
import re
import argparse
import re
from typing import List, Dict, Set, Tuple, Optional

# ----------------------------------------------------------------------
# Regexes for the language constructs
# ----------------------------------------------------------------------
IF_RE      = re.compile(r'^\s*if\s*\(\s*(?P<cond>.*)\s*\)\s*$', re.IGNORECASE)
ELSEIF_RE  = re.compile(r'^\s*elseif\s*\(\s*(?P<cond>.*)\s*\)\s*$', re.IGNORECASE)
ELSE_RE    = re.compile(r'^\s*else\s*\(?\)?\s*$', re.IGNORECASE)
ENDIF_RE   = re.compile(r'^\s*endif\s*\(?\)?\s*$', re.IGNORECASE)

# ----------------------------------------------------------------------
# Logical‑operator helpers
# ----------------------------------------------------------------------
_LOGICAL_SPLIT = re.compile(
    r'\s+(?:AND|OR|&&|\|\|)\s+',   # split on any logical operator, case‑insensitive
    flags=re.IGNORECASE,
)

_OR_OPERATOR   = re.compile(r'\bOR\b|\|\|', flags=re.IGNORECASE)
_AND_OPERATOR  = re.compile(r'\bAND\b|&&', flags=re.IGNORECASE)
_NOT_PREFIX    = re.compile(r'^\s*NOT\s+', flags=re.IGNORECASE)
_OUTER_PARENS  = re.compile(r'^\(\s*(.*)\s*\)$', flags=re.DOTALL)

# ----------------------------------------------------------------------
# Helper: recognise a leading NOT (inverse condition)
# ----------------------------------------------------------------------
def _is_negated(part: str) -> bool:
    """Return True if *part* starts with the keyword NOT (case‑insensitive)."""
    return bool(_NOT_PREFIX.match(part.strip()))

# ----------------------------------------------------------------------
# Helper: case‑insensitive “ends with one of the words”
# ----------------------------------------------------------------------
def _ends_with_word(token: str, words: List[str]) -> bool:
    token_low = token.lower()
    return any(token_low.endswith(w.lower()) for w in words)

# ----------------------------------------------------------------------
# Condition handling utilities
# ----------------------------------------------------------------------
def _strip_not_and_outer_parens(expr: str) -> Tuple[bool, str]:
    """Detect a leading NOT and a single outer pair of parentheses."""
    has_not = False
    m = _NOT_PREFIX.match(expr)
    if m:
        has_not = True
        expr = expr[m.end():]           # drop the NOT token

    m = _OUTER_PARENS.match(expr.strip())
    if m:
        expr = m.group(1)

    return has_not, expr.strip()


def _subconditions(cond: str) -> List[str]:
    """Break a raw condition into atomic sub‑conditions."""
    parts = _LOGICAL_SPLIT.split(cond.strip())
    return [p.strip("() ").strip() for p in parts if p]


def _condition_needs_full_removal(cond: str, words: List[str]) -> bool:
    """Return True if any **positive** sub‑condition ends with a target word."""
    for part in _subconditions(cond):
        if not part or _is_negated(part):
            continue                # ignore negated operands
        last_token = part.split()[-1]
        if _ends_with_word(last_token, words):
            return True
    return False


# ----------------------------------------------------------------------
# AST node definitions for the expression parser
# ----------------------------------------------------------------------
class _Node:
    pass

class Var(_Node):
    def __init__(self, text: str):
        self.text = text

class Not(_Node):
    def __init__(self, child: _Node):
        self.child = child

class And(_Node):
    def __init__(self, left: _Node, right: _Node):
        self.left = left
        self.right = right

class Or(_Node):
    def __init__(self, left: _Node, right: _Node):
        self.left = left
        self.right = right


# ----------------------------------------------------------------------
# Parser – shunting‑yard algorithm → AST
# ----------------------------------------------------------------------
_TOKEN_RE = re.compile(r'\(|\)|\bAND\b|\bOR\b|\bNOT\b|[^\s()]+', flags=re.IGNORECASE)

def _parse_condition(expr: str) -> Optional[_Node]:
    """
    Parse a CMake logical expression into an AST.
    Returns the root node, or ``None`` if the expression is empty.
    """
    tokens = _TOKEN_RE.findall(expr)
    output: List[_Node] = []
    ops: List[str] = []          # operator stack (strings)

    # operator precedence (higher number = higher precedence)
    prec = {"NOT": 3, "AND": 2, "OR": 1}
    # NOT is right‑associative, AND/OR left‑associative
    assoc = {"NOT": "right", "AND": "left", "OR": "left"}

    def apply_op():
        """Pop one operator from ops and push the resulting node onto output."""
        op = ops.pop()
        if op == "NOT":
            # unary
            if not output:
                return
            child = output.pop()
            output.append(Not(child))
        else:
            # binary
            if len(output) < 2:
                return
            right = output.pop()
            left = output.pop()
            if op == "AND":
                output.append(And(left, right))
            elif op == "OR":
                output.append(Or(left, right))

    i = 0
    while i < len(tokens):
        tok = tokens[i]
        up = tok.upper()
        if up in ("AND", "OR", "NOT"):
            while ops:
                top = ops[-1]
                if top == "(":
                    break
                if (prec[top] > prec[up]) or (prec[top] == prec[up] and assoc[up] == "left"):
                    apply_op()
                else:
                    break
            ops.append(up)
        elif tok == "(":
            ops.append(tok)
        elif tok == ")":
            while ops and ops[-1] != "(":
                apply_op()
            if ops and ops[-1] == "(":
                ops.pop()   # discard '('
        else:
            # operand (variable, literal, etc.)
            output.append(Var(tok))
        i += 1

    while ops:
        apply_op()

    return output[0] if output else None


# ----------------------------------------------------------------------
# Prune the AST – drop operands that end with a removal word
# ----------------------------------------------------------------------
def _prune_ast(node: _Node, words: List[str]) -> Optional[_Node]:
    """
    Recursively prune an AST:

    * ``Var`` nodes whose text ends with a word from *words* are removed
      (return ``None``).
    * ``Not`` nodes are **never** removed – their child is kept unchanged.
    * ``And`` / ``Or`` nodes keep any surviving child; if both disappear the
      node itself disappears.
    """
    if isinstance(node, Var):
        if _ends_with_word(node.text, words):
            return None
        return node

    if isinstance(node, Not):
        # Negated operands are never removed – keep the NOT node as‑is.
        return Not(node.child)

    if isinstance(node, And):
        left = _prune_ast(node.left, words)
        right = _prune_ast(node.right, words)
        if left is None and right is None:
            return None
        if left is None:
            return right
        if right is None:
            return left
        return And(left, right)

    if isinstance(node, Or):
        left = _prune_ast(node.left, words)
        right = _prune_ast(node.right, words)
        if left is None and right is None:
            return None
        if left is None:
            return right
        if right is None:
            return left
        return Or(left, right)

    return None   # safety


# ----------------------------------------------------------------------
# Convert AST back to a string (with minimal parentheses)
# ----------------------------------------------------------------------
def _ast_to_string(node: _Node) -> str:
    if isinstance(node, Var):
        return node.text
    if isinstance(node, Not):
        child_str = _ast_to_string(node.child)
        # Add parentheses if the child is a binary operator
        if isinstance(node.child, (And, Or)):
            child_str = f"({child_str})"
        return f"NOT {child_str}"
    if isinstance(node, And):
        left = _ast_to_string(node.left)
        right = _ast_to_string(node.right)
        # Parentheses are required when this AND is nested inside an OR
        return f"({left} AND {right})"
    if isinstance(node, Or):
        left = _ast_to_string(node.left)
        right = _ast_to_string(node.right)
        return f"({left} OR {right})"
    return ""   # should never happen


# ----------------------------------------------------------------------
# Simplify a condition by parsing, pruning, and re‑stringifying
# ----------------------------------------------------------------------
def _simplify_condition(cond: str, words: List[str]) -> Optional[str]:
    """
    Return a new condition string after removing every operand that ends with a
    word from *words*.  If the whole expression disappears, return ``None``.
    """
    ast = _parse_condition(cond)
    if ast is None:
        return None
    pruned = _prune_ast(ast, words)
    if pruned is None:
        return None
    simplified = _ast_to_string(pruned)

    # Strip outermost parentheses that are now redundant
    simplified = simplified.strip()
    while simplified.startswith('(') and simplified.endswith(')'):
        # Ensure that the outer pair really encloses the whole expression
        inner = simplified[1:-1].strip()
        # Count parentheses inside; if they balance we can strip.
        if inner.count('(') == inner.count(')'):
            simplified = inner
        else:
            break
    return simplified


# ----------------------------------------------------------------------
# NEW: robust flattening of  LEFT AND (B OR C …)  →  LEFT OR B OR C …
# ----------------------------------------------------------------------
def _flatten_and_or(cond: str, words: List[str]) -> Optional[str]:
    """
    Flatten a pattern ``LEFT AND (B OR C …)`` **only if at least one operand**
    ends with a word from *words*.
    Returns the transformed condition, or ``None`` if no change is required.
    """
    # Guard – need at least one matching positive operand
    parts = _subconditions(cond)
    positive_match = any(
        not _is_negated(p) and _ends_with_word(p.split()[-1], words)
        for p in parts if p
    )
    if not positive_match:
        return None                     # nothing to flatten

    try:
        from re import Match as _ReMatch   # Python ≥3.5
    except ImportError:                     # pragma: no cover
        _ReMatch = object                  # fallback

    pattern = re.compile(
        r'''
        (?P<left>[^()]+?)          # left side – any chars up to '('
        \s+(?i:AND)\s*             # the word AND (case‑insensitive)
        \(\s*(?P<inner>[^)]+?)\s*\)   # inner parentheses
        ''',
        flags=re.VERBOSE,
    )

    def replace_one(match: _ReMatch) -> str:
        left = match.group('left').strip()
        inner = match.group('inner').strip()
        if not _OR_OPERATOR.search(inner):
            return match.group(0)
        inner_parts = [p.strip() for p in _OR_OPERATOR.split(inner) if p.strip()]
        return " OR ".join([left] + inner_parts)

    changed = False
    while True:
        new_cond = pattern.sub(lambda m: replace_one(m), cond)
        if new_cond == cond:
            break
        cond = new_cond
        changed = True

    return cond if changed else None


# ----------------------------------------------------------------------
# OR‑chain shrinking (only when a positive operand matches)
# ----------------------------------------------------------------------
def _process_or_condition(cond: str, words: List[str]) -> Tuple[Optional[str], bool]:
    """
    Shrink an OR‑chain **only when at least one positive operand** ends with a
    word from *words*.  Negated operands are never removed.
    Returns (new_condition, remove_all).  ``new_condition`` is ``None`` when
    no rewrite is needed.
    """
    parts = _subconditions(cond)

    any_match = any(
        not _is_negated(p) and _ends_with_word(p.split()[-1], words)
        for p in parts if p
    )
    if not any_match:
        return None, False                     # nothing to change

    remaining = [
        p for p in parts
        if _is_negated(p) or not _ends_with_word(p.split()[-1], words)
    ]

    if not remaining:                     # everything matched → drop block
        return None, True

    new_inner = " OR ".join(remaining)

    has_not, _ = _strip_not_and_outer_parens(cond)
    if has_not:
        new_inner = f"NOT ({new_inner})"
    else:
        if cond.strip().startswith('(') and cond.strip().endswith(')'):
            new_inner = f"({new_inner})"

    return new_inner, False


def evaluate_condition(cond: str, words: List[str]) -> Tuple[Optional[str], bool]:
    """
    Decide what to do with an IF/ELSEIF condition.
    Returns (new_condition, remove_block). ``new_condition`` may be ``None``
    (meaning the IF line should be left unchanged) and ``remove_block`` tells
    the caller whether the surrounding IF‑ENDIF block must be eliminated.
    """
    # ------------------------------------------------------------------
    # 0️⃣ First simplify – prune matching operands from the whole tree.
    # ------------------------------------------------------------------
    simplified = _simplify_condition(cond, words)
    if simplified is None:
        # Everything vanished → delete the whole IF block.
        return None, True
    cond = simplified

    # ------------------------------------------------------------------
    # 1️⃣ Try the AND‑OR flattening (now on the simplified condition)
    # ------------------------------------------------------------------
    flat = _flatten_and_or(cond, words)
    if flat is not None:
        return flat, False

    # ------------------------------------------------------------------
    # 2️⃣ OR‑shrink (only when a positive operand matches)
    # ------------------------------------------------------------------
    if _OR_OPERATOR.search(cond):
        return _process_or_condition(cond, words)

    # ------------------------------------------------------------------
    # 3️⃣ No OR – whole‑block removal if any positive sub‑condition matches
    # ------------------------------------------------------------------
    return None, _condition_needs_full_removal(cond, words)


# ----------------------------------------------------------------------
# Re‑building a conditional line while preserving the exact whitespace
# ----------------------------------------------------------------------
def _rebuild_conditional_line(original_line: str,
                              new_cond: Optional[str] = None) -> str:
    """Re‑create a conditional line (IF/ELSEIF) preserving original spacing."""
    newline = "\n" if original_line.endswith("\n") else ""

    m = re.match(r'^(\s*)(if|elseif|else|endif)(\s*)\(', original_line,
                 re.IGNORECASE)
    if not m:
        return original_line

    leading_ws, keyword, ws_after = m.group(1), m.group(2), m.group(3)

    if new_cond is None:
        m_cond = IF_RE.match(original_line.rstrip("\n"))
        if not m_cond:
            return original_line
        new_cond = m_cond.group("cond").strip()

    return f"{leading_ws}{keyword}{ws_after}({new_cond}){newline}"


# ----------------------------------------------------------------------
# Helper: should an ASSERT_DEFINED line be removed? (single‑line)
# ----------------------------------------------------------------------
_ASSERT_RE = re.compile(r'^\s*ASSERT_DEFINED\s*\(\s*([^\)]+)\)', re.IGNORECASE)

def _assert_defined_needs_removal(line: str, words: List[str]) -> bool:
    """Return True if any argument of a single‑line ASSERT_DEFINED ends with a word."""
    m = _ASSERT_RE.match(line)
    if not m:
        return False
    args = m.group(1)
    for token in args.split():
        token_clean = token.strip("{}$")
        if _ends_with_word(token_clean, words):
            return True
    return False


# ----------------------------------------------------------------------
# Helper: should a GLOBAL_SET line be removed?
# ----------------------------------------------------------------------
_GLOBAL_SET_RE = re.compile(r'^\s*GLOBAL_SET\s*\(\s*([^\)]+)\)', re.IGNORECASE)

def _global_set_needs_removal(line: str, words: List[str]) -> bool:
    """Return True if any argument of GLOBAL_SET ends with a word."""
    m = _GLOBAL_SET_RE.match(line)
    if not m:
        return False
    args = m.group(1)
    for token in args.split():
        token_clean = token.strip("{}$")
        if _ends_with_word(token_clean, words):
            return True
    return False


# ----------------------------------------------------------------------
# NEW: multi‑line ASSERT_DEFINED handling
# ----------------------------------------------------------------------
_ASSERT_START_RE = re.compile(r'^\s*ASSERT_DEFINED\s*\(\s*$', re.IGNORECASE)
_ASSERT_END_RE   = re.compile(r'\)')                     # any line containing a closing ')'

def _token_matches_word(token: str, words: List[str]) -> bool:
    token_clean = token.strip("{}$")
    return _ends_with_word(token_clean, words)


# ----------------------------------------------------------------------
# Core removal routine (now supports multi‑line IF and ASSERT_DEFINED)
# ----------------------------------------------------------------------
def remove_if_statements(lines: List[str], words: List[str]) -> List[str]:
    """
    Walk through *lines* and either delete whole IF‑ENDIF blocks (keeping the
    ELSE body when appropriate), shrink OR‑chained conditions (including the
    new AND‑OR flattening), delete ASSERT_DEFINED/GLOBAL_SET lines whose
    arguments end with one of the words, and handle multi‑line IF and
    ASSERT_DEFINED statements.
    Returns a new list of lines.
    """
    stack: List[Dict] = []          # each entry: {"start": idx, "remove": bool}
    to_remove: Set[int] = set()    # line numbers that will be omitted
    replacements: Dict[int, str] = {}   # rewritten IF lines (single‑line)
    dedent_map: Dict[int, str] = {}     # line idx → indentation to strip

    # State for a multi‑line ASSERT_DEFINED block
    in_assert = False
    assert_start = None
    assert_body_idxs: List[int] = []   # indices of argument lines inside the block
    assert_removed_body: Set[int] = set()   # which of those lines are removed

    i = 0
    while i < len(lines):
        raw_line = lines[i]
        line = raw_line.rstrip("\n")   # keep original spacing for output

        # --------------------------------------------------------------
        # 0️⃣  Remove GLOBAL_SET lines first (single‑line only)
        # --------------------------------------------------------------
        if _global_set_needs_removal(line, words):
            to_remove.add(i)
            i += 1
            continue

        # --------------------------------------------------------------
        # 0️⃣  Handle multi‑line ASSERT_DEFINED block
        # --------------------------------------------------------------
        if in_assert:
            # Inside a multi‑line ASSERT_DEFINED block.
            if _ASSERT_END_RE.search(line):
                # Closing line – decide what to do with the whole block.
                if len(assert_body_idxs) == len(assert_removed_body):
                    # whole block empty → remove opening and closing lines
                    to_remove.add(assert_start)          # opening line
                    to_remove.add(i)                     # closing line
                # reset state
                in_assert = False
                assert_start = None
                assert_body_idxs.clear()
                assert_removed_body.clear()
                i += 1
                continue

            # Not the closing line – treat this as an argument line.
            assert_body_idxs.append(i)
            for token in line.split():
                if _token_matches_word(token, words):
                    to_remove.add(i)
                    assert_removed_body.add(i)
                    break   # line removed – no need to examine further tokens
            i += 1
            continue

        # --------------------------------------------------------------
        # 0️⃣  Detect start of a multi‑line ASSERT_DEFINED
        # --------------------------------------------------------------
        if _ASSERT_START_RE.match(line):
            in_assert = True
            assert_start = i
            i += 1
            continue

        # --------------------------------------------------------------
        # 0️⃣  Single‑line ASSERT_DEFINED removal (already handled above
        #      but keep for completeness)
        # --------------------------------------------------------------
        if _assert_defined_needs_removal(line, words):
            to_remove.add(i)
            i += 1
            continue

        # --------------------------------------------------------------
        # 1️⃣ Detect IF header – single‑line or multi‑line
        # --------------------------------------------------------------
        if re.match(r'^\s*if\s*\(', line, re.IGNORECASE):
            # Does the line already contain a closing ')' ?
            if ')' in line:
                m_if = IF_RE.match(line)
                cond = m_if.group("cond") if m_if else ""
                header_start = i
                header_end   = i
                i += 1
            else:
                # ----- MULTI‑LINE IF -----
                header_start = i
                # Grab everything after the first '(' on this line
                first_part = line.split('(', 1)[1]
                cond_parts = [first_part]

                i += 1
                while i < len(lines):
                    nxt = lines[i].rstrip("\n")
                    if ')' in nxt:
                        before, _ = nxt.split(')', 1)
                        cond_parts.append(before)
                        header_end = i
                        i += 1
                        break
                    else:
                        cond_parts.append(nxt)
                        i += 1

                cond = " ".join(p.strip() for p in cond_parts).strip()

            # ------------------------------------------------------------------
            # Evaluate the condition (may be rewritten or cause block removal)
            # ------------------------------------------------------------------
            new_cond, remove_block = evaluate_condition(cond, words)

            if remove_block:
                stack.append({"start": header_start, "remove": True})
            else:
                stack.append({"start": header_start, "remove": False})
                if new_cond is not None:
                    # Rewrite the (possibly multi‑line) IF header as a single line.
                    leading_ws = re.match(r'^(\s*)', lines[header_start]).group(1)
                    new_if_line = f"{leading_ws}IF({new_cond})\n"
                    replacements[header_start] = new_if_line
                    # Remove any extra lines that were part of the original header.
                    for rm_idx in range(header_start + 1, header_end + 1):
                        to_remove.add(rm_idx)
            continue   # i already points after the header

        # --------------------------------------------------------------
        # 2️⃣ ENDIF – close the most recent IF
        # --------------------------------------------------------------
        if ENDIF_RE.match(line):
            if not stack:
                i += 1
                continue                     # stray ENDIF – ignore
            block = stack.pop()
            if block["remove"]:
                # Look for an ELSE inside this block.
                else_idx: Optional[int] = None
                for idx in range(block["start"], i):
                    if ELSE_RE.match(lines[idx].rstrip("\n")):
                        else_idx = idx
                        break

                if else_idx is not None:
                    # --------- block has an ELSE ----------
                    # Remove IF line through the ELSE line (inclusive)
                    for idx in range(block["start"], else_idx + 1):
                        to_remove.add(idx)

                    # Remove the matching ENDIF line
                    to_remove.add(i)

                    # Back‑dent the ELSE body (lines between ELSE+1 and ENDIF‑1)
                    if_indent = re.match(r'^(\s*)', lines[block["start"]]).group(1)
                    for idx in range(else_idx + 1, i):
                        dedent_map[idx] = if_indent
                else:
                    # No ELSE – remove the whole block including ENDIF.
                    for idx in range(block["start"], i + 1):
                        to_remove.add(idx)
            i += 1
            continue

        # --------------------------------------------------------------
        # 3️⃣ Anything else – just advance
        # --------------------------------------------------------------
        i += 1

    # ------------------------------------------------------------------
    # Assemble the final output, applying replacements, removals and dedent.
    # ------------------------------------------------------------------
    result: List[str] = []
    for idx, ln in enumerate(lines):
        if idx in to_remove:
            continue
        if idx in replacements:
            result.append(replacements[idx])
            continue

        if idx in dedent_map:
            indent = dedent_map[idx]
            if ln.startswith(indent):
                ln = ln[len(indent):]
        result.append(ln)

    return result


def process_lists_file(file_path, words):
    # Read the content of the file
    with open(file_path, 'r') as file:
        content = file.readlines()

    # Remove specified if statements
    modified_content = remove_if_statements(content, words)

    # Write the modified content back to the file
    with open(file_path, 'w') as file:
        file.writelines(modified_content)

import pathlib

def find_and_process_lists_files(directory, words):
    # Walk through the directory to find all CMakeLists.txt files
    for root, _, files in os.walk(directory):
        for file in files:
            if file == 'CMakeLists.txt':
                file_path = os.path.join(root, file)
                print(f"Processing file: {file_path}")
                process_lists_file(file_path, words)

def find_cmake_files_with_words(
    root_dir,
    words,
    *,
    ignore_case: bool = False,
    whole_word: bool = True,
):
    """
    Search a directory tree for CMake files that contain any of the given words.

    Parameters
    ----------
    root_dir : str or pathlib.Path
        The directory that will.
    words : iterable of str
        Words (or regex‑compatible tokens) to look for.
    ignore_case : bool, default False
        Perform a case‑insensitive search.
    whole_word : bool, default True
        If True, matches are bounded by word‑boundary ``\\b`` so that
        ``find`` does not match ``find_package`` when searching for ``find``.
        Set to False to allow substring matches.

    Returns
    -------
    dict[pathlib.Path, list[str]]
        Mapping from each CMake file that contains at least one word to a
        **sorted** list of the distinct words that were found in that file.

    Notes
    -----
    * Files are opened with UTF‑8 encoding; if that fails they are reopened with
      ``latin‑1`` (a loss‑less fallback for binary data) so the function never
      raises a ``UnicodeDecodeError``.
    * The search is performed line‑by‑line to keep memory usage low even for
      large CMake files.
    """
    # Normalise inputs --------------------------------------------------------
    root = pathlib.Path(root_dir).expanduser().resolve()
    if not root.is_dir():
        raise ValueError(f"{root!s} is not a directory")

    # Build a single regular expression that matches any of the target words.
    # Example: r'\b(add_library|find_package|Boost)\b'
    escaped_words = [re.escape(w) for w in words if w]  # ignore empty strings
    if not escaped_words:
        return {}

    pattern = "|".join(escaped_words)
    if whole_word:
        pattern = rf"\b({pattern})\b"
    else:
        pattern = f"({pattern})"

    flags = re.MULTILINE
    if ignore_case:
        flags |= re.IGNORECASE

    regex = re.compile(pattern, flags)

    # Result container ---------------------------------------------------------
    hits: Dict[pathlib.Path, Set[str]] = {}

    # Walk the tree ------------------------------------------------------------
    for file_path in root.rglob("*"):
        # Keep only CMakeLists.txt or *.cmake files
        if not (
            file_path.is_file()
            and (file_path.name == "CMakeLists.txt" or file_path.suffix == ".cmake")
        ):
            continue

        # Try reading the file (first UTF‑8, then latin‑1 fallback)
        try:
            text = file_path.read_text(encoding="utf-8")
        except UnicodeDecodeError:
            text = file_path.read_text(encoding="latin-1")

        # Scan line‑by‑line – this also gives us the opportunity to short‑circuit
        # once we have found all possible words.
        found_in_this_file: Set[str] = set()
        for line in text.splitlines():
            for m in regex.finditer(line):
                # ``m.group(1)`` is the word that matched the alternation
                found_in_this_file.add(m.group(1))

            # Optional early exit: if we already found every word we can stop.
            if len(found_in_this_file) == len(escaped_words):
                break

        if found_in_this_file:
            hits[os.path.relpath(file_path, root_dir)] = found_in_this_file

    # Convert sets to sorted lists for a clean public API
    return {p: sorted(list(s)) for p, s in hits.items()}


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="Tool to iterate through 'CMakeLists.txt' files and attempt to remove conditional code related to deprecated Trilinos packages.\nWILL NOT WORK IN ALL CASES.\nWill not remove comments related to deprecated packages.\n\nThe tool will them summarize REMAINING deprecated-package-related words that are left in CMakeList.txt and *.cmake files.")
    parser.parse_args()
    target_directory = os.getcwd()

    words_to_remove = ['Amesos', 'AztecOO', 'Epetra', 'EpetraExt', 'Ifpack', 'Intrepid', 'Isorropia', 'ML', 'NewPackage', 'Pliris', 'PyTrilinos', 'ShyLU_DDCore', 'ThyraEpetraAdapters', 'ThyraEpetraExtAdapters', 'Triutils']

    find_and_process_lists_files(target_directory, words_to_remove)

    words = words_to_remove
    words.remove("ML")
    words.append("_ML")
    remaining_files = find_cmake_files_with_words(os.getcwd(), ignore_case=True, words=words_to_remove, whole_word=False)

    print("\n\nRemaining CMakeLists.txt files containing any words related to deprecated packages:\n\n--> I am being deliberate about looking for _ML because otherwise 'ml' is too common, find that one manually\n\n")
    for f, matches in remaining_files.items():
        print(f"{f}:")
        print("  ", end="")
        print("\n  ".join(matches))
