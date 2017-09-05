
// @HEADER
// ************************************************************************
//
//               Rapid Optimization Library (ROL) Package
//                 Copyright (2014) Sandia Corporation
//
// Under terms of Contract DE-AC04-94AL85000, there is a non-exclusive
// license for use of this work by or on behalf of the U.S. Government.
//
// Redistribution and use in source and binary forms, with or without
// modification, are permitted provided that the following conditions are
// met:
//
// 1. Redistributions of source code must retain the above copyright
// notice, this list of conditions and the following disclaimer.
//
// 2. Redistributions in binary form must reproduce the above copyright
// notice, this list of conditions and the following disclaimer in the
// documentation and/or other materials provided with the distribution.
//
// 3. Neither the name of the Corporation nor the names of the
// contributors may be used to endorse or promote products derived from
// this software without specific prior written permission.
//
// THIS SOFTWARE IS PROVIDED BY SANDIA CORPORATION "AS IS" AND ANY
// EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
// IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR
// PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL SANDIA CORPORATION OR THE
// CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL,
// EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO,
// PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR
// PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF
// LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING
// NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
// SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
//
// Questions? Contact lead developers:
//              Drew Kouri   (dpkouri@sandia.gov) and
//              Denis Ridzal (dridzal@sandia.gov)
//
// ************************************************************************
// @HEADER

/*! \file  solver.hpp
    \brief Linear solvers for PDE-OPT.
*/

#ifndef ROL_PDEOPT_SOLVER_H
#define ROL_PDEOPT_SOLVER_H

#include "Teuchos_GlobalMPISession.hpp"
#include "Teuchos_TimeMonitor.hpp"

#include "Tpetra_DefaultPlatform.hpp"
#include "Tpetra_MultiVector.hpp"
#include "Tpetra_Vector.hpp"
#include "Tpetra_CrsGraph.hpp"
#include "Tpetra_CrsMatrix.hpp"
#include "Tpetra_Version.hpp"
#include "Tpetra_RowMatrixTransposer.hpp"
#include "TpetraExt_MatrixMatrix.hpp"
#include "MatrixMarket_Tpetra.hpp"

// Forward declarations.

namespace Amesos2 {
  template < typename tM, typename tV > class Solver;
}

namespace MueLu {
  template <typename tSC, typename tLO, typename tGO, typename tNO> class TpetraOperator;
}

namespace Ifpack2 {
  template <typename tSC, typename tLO, typename tGO, typename tNO> class Preconditioner;
}

namespace Belos {
  template <typename tSC, typename tMV, typename tOP> class BlockGmresSolMgr;
  template <typename tSC, typename tMV, typename tOP> class LinearProblem;
}


// Class declaration.

template<class Real>
class Solver {

  typedef Tpetra::Map<>::local_ordinal_type LO;
  typedef Tpetra::Map<>::global_ordinal_type GO;
  typedef Tpetra::Map<>::node_type NO;
  typedef Tpetra::MultiVector<Real,LO,GO,NO> MV;
  typedef Tpetra::Operator<Real,LO,GO,NO> OP;

private:

  // Linear solvers and preconditioners for Jacobian and adjoint Jacobian
  Teuchos::RCP<Amesos2::Solver< Tpetra::CrsMatrix<>, Tpetra::MultiVector<> > > solver_;
  Teuchos::RCP<MueLu::TpetraOperator<Real,LO,GO,NO> > mueLuPreconditioner_;
  Teuchos::RCP<MueLu::TpetraOperator<Real,LO,GO,NO> > mueLuPreconditioner_trans_;
  Teuchos::RCP<Ifpack2::Preconditioner<Real,LO,GO,NO> > ifpack2Preconditioner_;
  Teuchos::RCP<Ifpack2::Preconditioner<Real,LO,GO,NO> > ifpack2Preconditioner_trans_;
  Teuchos::RCP<Belos::BlockGmresSolMgr<Real,MV,OP> > solverBelos_;
  Teuchos::RCP<Belos::BlockGmresSolMgr<Real,MV,OP> > solverBelos_trans_;
  Teuchos::RCP<Belos::LinearProblem<Real,MV,OP> > problemBelos_;
  Teuchos::RCP<Belos::LinearProblem<Real,MV,OP> > problemBelos_trans_;

  // Linear solver options.
  bool useDirectSolver_;
  std::string directSolver_;
  std::string preconditioner_;

  // Matrix transpose.
  Teuchos::RCP<Tpetra::CrsMatrix<> > A_trans_;

  // Parameter list.
  Teuchos::ParameterList parlist_;
  Teuchos::RCP<Teuchos::ParameterList> parlistAmesos2_;

  // Construct solvers on first solve.
  bool firstSolve_;

public:

  virtual ~Solver() {}

  Solver(Teuchos::ParameterList & parlist) : parlist_(parlist), firstSolve_(true) {
    useDirectSolver_ = parlist.get("Use Direct Solver", true);
    directSolver_ = parlist.sublist("Direct").get("Solver Type", "KLU2");
    parlistAmesos2_ = Teuchos::rcp(new Teuchos::ParameterList("Amesos2"));
    preconditioner_ = parlist.get("Preconditioner", "Ifpack2");
  }

  void setA(Teuchos::RCP<Tpetra::CrsMatrix<> > &A);

  void solve(const Teuchos::RCP<Tpetra::MultiVector<> > &x,
             const Teuchos::RCP<const Tpetra::MultiVector<> > &b,
             const bool transpose = false);

};

#endif
