//@HEADER
// ************************************************************************
//
//               ShyLU: Hybrid preconditioner package
//                 Copyright 2012 Sandia Corporation
//
// Under the terms of Contract DE-AC04-94AL85000 with Sandia Corporation,
// the U.S. Government retains certain rights in this software.
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
// Questions? Contact Alexander Heinlein (alexander.heinlein@uni-koeln.de)
//
// ************************************************************************
//@HEADER

#ifndef _FROSCH_SUBDOMAINSOLVER_DECL_hpp
#define _FROSCH_SUBDOMAINSOLVER_DECL_hpp

#define FROSCH_ASSERT(A,S) if(!(A)) { std::cerr<<"Assertion failed. "<<S<<std::endl; std::cout.flush(); throw std::out_of_range("Assertion.");};

#include <ShyLU_DDFROSch_config.h>

#ifdef HAVE_SHYLU_DDFROSCH_EPETRA
#include "Epetra_LinearProblem.h"
#endif

#ifdef HAVE_SHYLU_DDFROSCH_AMESOS
#include "Amesos_ConfigDefs.h"
#include "Amesos.h"
#include "Amesos_BaseSolver.h"
#endif

#include "Amesos2.hpp"

#ifdef HAVE_SHYLU_DDFROSCH_BELOS
#include <BelosXpetraAdapterOperator.hpp>
#include <BelosOperatorT.hpp>
#include <BelosXpetraAdapter.hpp>
#include <BelosSolverFactory.hpp>
#endif

#ifdef HAVE_SHYLU_DDFROSCH_MUELU
//#include <MueLu.hpp>
#include <MueLu_TpetraOperator.hpp>
#include <MueLu_CreateTpetraPreconditioner.hpp>
#include <MueLu_Utilities.hpp>
#endif

namespace FROSch {

    template <class SC,
    class LO ,
    class GO ,
    class NO >
    class OneLevelPreconditioner;

    template <class SC = typename Xpetra::Operator<>::scalar_type,
    class LO = typename Xpetra::Operator<SC>::local_ordinal_type,
    class GO = typename Xpetra::Operator<SC, LO>::global_ordinal_type,
    class NO = typename Xpetra::Operator<SC, LO, GO>::node_type>
    class SubdomainSolver : public Xpetra::Operator<SC,LO,GO,NO> {

    public:

        typedef Xpetra::Map<LO,GO,NO> Map;
        typedef Teuchos::RCP<Map> MapPtr;
        typedef Teuchos::RCP<const Map> ConstMapPtr;
        typedef Teuchos::ArrayRCP<MapPtr> MapPtrVecPtr;

        typedef Teuchos::ArrayRCP<GO> GOVecPtr;


        typedef Xpetra::Matrix<SC,LO,GO,NO> CrsMatrix;
        typedef Teuchos::RCP<CrsMatrix> CrsMatrixPtr;
#ifdef HAVE_SHYLU_DDFROSCH_EPETRA
        typedef Epetra_CrsMatrix EpetraCrsMatrix;
        typedef Teuchos::RCP<EpetraCrsMatrix> EpetraCrsMatrixPtr;
#endif
        typedef Tpetra::CrsMatrix<SC,LO,GO,NO> TpetraCrsMatrix;
        typedef Teuchos::RCP<TpetraCrsMatrix> TpetraCrsMatrixPtr;

        typedef Xpetra::MultiVector<SC,LO,GO,NO> MultiVector;
        typedef Teuchos::RCP<MultiVector> MultiVectorPtr;
        typedef Teuchos::RCP<const MultiVector> ConstMultiVectorPtr;
#ifdef HAVE_SHYLU_DDFROSCH_EPETRA
        typedef Epetra_MultiVector EpetraMultiVector;
        typedef Teuchos::RCP<EpetraMultiVector> EpetraMultiVectorPtr;
#endif
        typedef Tpetra::MultiVector<SC,LO,GO,NO> TpetraMultiVector;
        typedef Teuchos::RCP<TpetraMultiVector> TpetraMultiVectorPtr;

        typedef Teuchos::RCP<Teuchos::ParameterList> ParameterListPtr;

#ifdef HAVE_SHYLU_DDFROSCH_EPETRA
        typedef Teuchos::RCP<Epetra_LinearProblem> LinearProblemPtr;
#endif

#ifdef HAVE_SHYLU_DDFROSCH_AMESOS
        typedef Teuchos::RCP<Amesos_BaseSolver> AmesosSolverPtr;
#endif

#ifdef HAVE_SHYLU_DDFROSCH_EPETRA
        typedef Teuchos::RCP<Amesos2::Solver<EpetraCrsMatrix,EpetraMultiVector> > Amesos2SolverEpetraPtr;
#endif
        typedef Teuchos::RCP<Amesos2::Solver<TpetraCrsMatrix,TpetraMultiVector> > Amesos2SolverTpetraPtr;

#ifdef HAVE_SHYLU_DDFROSCH_MUELU
        typedef Teuchos::RCP<MueLu::HierarchyManager<SC,LO,GO,NO> > MueLuFactoryPtr;
        typedef Teuchos::RCP<MueLu::Hierarchy<SC,LO,GO,NO> > MueLuHierarchyPtr;
#endif

        /*!
        \brief Constructor

        Create the subdomain solver object.

        A subdomain solver might require further Trilinos packages at runtime.
        Availability of required packages is tested and
        an error is thrown if required packages are not part of the build configuration.

        @param k Matrix
        @param parameterList Parameter list
        @param blockCoarseSize
        */
        SubdomainSolver(CrsMatrixPtr k,
                        ParameterListPtr parameterList,
                        GOVecPtr blockCoarseSize=Teuchos::null);

        //! Destructor
        virtual ~SubdomainSolver();

        //! Initialize member variables
        virtual int initialize();

        /*!
        \brief Compute/setup this operator/solver

        \pre Routine initialize() has been called and #isInitialized_ is set to \c true.

        @return Integer error code
        */
        virtual int compute();

        /*! \brief Apply subdomain solver to input \c x
         *
         * y = alpha * A^mode * X + beta * Y
         *
         * \param[in] x Input vector
         * \param[out] y result vector
         * \param[in] mode
         */

        /*!
        \brief Computes the operator-multivector application.

        Loosely, performs \f$Y = \alpha \cdot A^{\textrm{mode}} \cdot X + \beta \cdot Y\f$. However, the details of operation
        vary according to the values of \c alpha and \c beta. Specifically
        - if <tt>beta == 0</tt>, apply() <b>must</b> overwrite \c Y, so that any values in \c Y (including NaNs) are ignored.
        - if <tt>alpha == 0</tt>, apply() <b>may</b> short-circuit the operator, so that any values in \c X (including NaNs) are ignored.
        */
        virtual void apply(const MultiVector &x,
                           MultiVector &y,
                           Teuchos::ETransp mode=Teuchos::NO_TRANS,
                           SC alpha=Teuchos::ScalarTraits<SC>::one(),
                           SC beta=Teuchos::ScalarTraits<SC>::zero()) const;

        //! Get domain map
        virtual ConstMapPtr getDomainMap() const;

        //! Get range map
        virtual ConstMapPtr getRangeMap() const;

        /*!
        \brief Print description of this object to given output stream

        \param out Output stream to be used
        \param Verbosity level used for printing
        */
        virtual void describe(Teuchos::FancyOStream &out,
                              const Teuchos::EVerbosityLevel verbLevel=Teuchos::Describable::verbLevel_default) const;

        /*!
        \brief Get description of this operator

        \return String describing this operator
        */
        virtual std::string description() const;

        //! @name Access to class members
        //!@{

        //! Get #IsInitialized_
        bool isInitialized() const;

        //! Get #IsComputed_
        bool isComputed() const;

        //!@}

    protected:

        //! Matrix
        CrsMatrixPtr K_;

        //! Paremter list
        ParameterListPtr ParameterList_;

#ifdef HAVE_SHYLU_DDFROSCH_EPETRA
        LinearProblemPtr EpetraLinearProblem_;
#endif

#ifdef HAVE_SHYLU_DDFROSCH_AMESOS
        AmesosSolverPtr AmesosSolver_;
#endif

#ifdef HAVE_SHYLU_DDFROSCH_EPETRA
        Amesos2SolverEpetraPtr Amesos2SolverEpetra_;
#endif
        Amesos2SolverTpetraPtr Amesos2SolverTpetra_;

#ifdef HAVE_SHYLU_DDFROSCH_MUELU
        //! Factory to create a MueLu hierarchy
        MueLuFactoryPtr MueLuFactory_;

        //! MueLu hierarchy object
        MueLuHierarchyPtr MueLuHierarchy_;
#endif

#ifdef HAVE_SHYLU_DDFROSCH_BELOS
        Teuchos::RCP<Belos::LinearProblem<SC,Xpetra::MultiVector<SC,LO,GO,NO>,Belos::OperatorT<Xpetra::MultiVector<SC,LO,GO,NO> > > >  BelosLinearProblem_;
        Teuchos::RCP<Belos::SolverManager<SC,Xpetra::MultiVector<SC,LO,GO,NO>,Belos::OperatorT<Xpetra::MultiVector<SC,LO,GO,NO> > > > BelosSolverManager_;
#endif

        bool IsInitialized_;

        //! Flag to indicated whether this subdomain solver has been setup/computed
        bool IsComputed_;
    };

}

#endif
