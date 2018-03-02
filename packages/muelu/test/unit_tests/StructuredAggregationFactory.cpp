// @HEADER
//
// ***********************************************************************
//
//        MueLu: A package for multigrid based preconditioning
//                  Copyright 2012 Sandia Corporation
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
// Questions? Contact
//                    Jonathan Hu       (jhu@sandia.gov)
//                    Andrey Prokopenko (aprokop@sandia.gov)
//                    Ray Tuminaro      (rstumin@sandia.gov)
//
// ***********************************************************************
//
// @HEADER
#include "Teuchos_UnitTestHarness.hpp"
#include "MueLu_TestHelpers.hpp"
#include "MueLu_Version.hpp"

#include "MueLu_StructuredAggregationFactory.hpp"
#include "MueLu_AmalgamationFactory.hpp"
#include "MueLu_CoalesceDropFactory.hpp"
#include "MueLu_TentativePFactory.hpp"
#include "MueLu_TrilinosSmoother.hpp"
#include "MueLu_Utilities.hpp"
#include "MueLu_TransPFactory.hpp"
#include "MueLu_RAPFactory.hpp"
#include "MueLu_SmootherFactory.hpp"
#include "MueLu_CoarseMapFactory.hpp"
#include "MueLu_LocalLexicographicIndexManager.hpp"

namespace MueLuTests {

  TEUCHOS_UNIT_TEST_TEMPLATE_4_DECL(StructuredAggregation, CreateGlobalLexicographicIndexManager, Scalar, LocalOrdinal, GlobalOrdinal, Node)
  {
#   include "MueLu_UseShortNames.hpp"
    MUELU_TESTING_SET_OSTREAM;
    MUELU_TESTING_LIMIT_SCOPE(Scalar,GlobalOrdinal,Node);

    out << "version: " << MueLu::Version() << std::endl;

    // Set global geometric data
    const int numDimensions = 2;
    const int interpolationOrder = 0;
    Array<GO> meshData;
    Array<LO> lNodesPerDir(3);
    Array<GO> gNodesPerDir(3);
    for(int dim = 0; dim < 3; ++dim) {
      if(dim < numDimensions) {
        // Use more nodes in 1D to have a reasonable number of nodes per procs
        gNodesPerDir[dim] = 6;
      } else {
        gNodesPerDir[dim] = 1;
      }
    }

    RCP<const Xpetra::MultiVector<double,LO,GO,NO> > Coordinates =
      TestHelpers::TestFactory<SC,LO,GO,NO>::BuildGeoCoordinates(numDimensions, gNodesPerDir,
                                                                 lNodesPerDir, meshData,
                                                                 "Global Lexicographic");

    RCP<const Teuchos::Comm<int> > comm = Coordinates->getMap()->getComm();
    Array<LO> coarseRate(1);
    coarseRate[0] = 3;
    RCP<MueLu::LocalLexicographicIndexManager<LO,GO,NO> > myIndexManager =
      rcp(new MueLu::LocalLexicographicIndexManager<LO,GO,NO>(numDimensions, interpolationOrder,
                                                              comm->getRank(), comm->getSize(),
                                                              gNodesPerDir, lNodesPerDir,
                                                              coarseRate, meshData));

  } // CreateGlobalLexicographicIndexManager

  TEUCHOS_UNIT_TEST_TEMPLATE_4_DECL(StructuredAggregation, CreateLocalLexicographicIndexManager, Scalar, LocalOrdinal, GlobalOrdinal, Node)
  {
#   include "MueLu_UseShortNames.hpp"
    MUELU_TESTING_SET_OSTREAM;
    MUELU_TESTING_LIMIT_SCOPE(Scalar,GlobalOrdinal,Node);

    out << "version: " << MueLu::Version() << std::endl;

    // Set global geometric data
    const int numDimensions = 2;
    const int interpolationOrder = 0;
    Array<GO> meshData;
    Array<LO> lNodesPerDir(3);
    Array<GO> gNodesPerDir(3);
    for(int dim = 0; dim < 3; ++dim) {
      if(dim < numDimensions) {
        // Use more nodes in 1D to have a reasonable number of nodes per procs
        gNodesPerDir[dim] = 6;
      } else {
        gNodesPerDir[dim] = 1;
      }
    }

    RCP<const Xpetra::MultiVector<double,LO,GO,NO> > Coordinates =
      TestHelpers::TestFactory<SC,LO,GO,NO>::BuildGeoCoordinates(numDimensions, gNodesPerDir,
                                                                 lNodesPerDir, meshData,
                                                                 "Local Lexicographic");

    RCP<const Teuchos::Comm<int> > comm = Coordinates->getMap()->getComm();
    Array<LO> coarseRate(1);
    coarseRate[0] = 3;
    RCP<MueLu::LocalLexicographicIndexManager<LO,GO,NO> > myIndexManager =
      rcp(new MueLu::LocalLexicographicIndexManager<LO,GO,NO>(numDimensions, interpolationOrder,
                                                              comm->getRank(), comm->getSize(),
                                                              gNodesPerDir, lNodesPerDir,
                                                              coarseRate, meshData));

  } // CreateLocalLexicographicIndexManager

  TEUCHOS_UNIT_TEST_TEMPLATE_4_DECL(StructuredAggregation, GlobalLexiTentative1D, Scalar, LocalOrdinal, GlobalOrdinal, Node)
  {
#   include "MueLu_UseShortNames.hpp"
    MUELU_TESTING_SET_OSTREAM;
    MUELU_TESTING_LIMIT_SCOPE(Scalar,GlobalOrdinal,Node);

    typedef Teuchos::ScalarTraits<Scalar> TST;
    typedef TestHelpers::TestFactory<Scalar, LocalOrdinal, GlobalOrdinal, Node> test_factory;

    out << "version: " << MueLu::Version() << std::endl;

    Level fineLevel, coarseLevel;
    test_factory::createTwoLevelHierarchy(fineLevel, coarseLevel);
    fineLevel.SetFactoryManager(Teuchos::null);  // factory manager is not used on this test
    coarseLevel.SetFactoryManager(Teuchos::null);

    // Set global geometric data
    const std::string meshLayout = "Global Lexicographic";
    LO numDimensions = 1;
    Array<GO> meshData;
    Array<LO> lNodesPerDir(3);
    Array<GO> gNodesPerDir(3);
    for(int dim = 0; dim < 3; ++dim) {
      if(dim < numDimensions) {
        // Use more nodes in 1D to have a reasonable number of nodes per procs
        gNodesPerDir[dim] = 20;
      } else {
        gNodesPerDir[dim] = 1;
      }
    }

    RCP<const Xpetra::MultiVector<double,LO,GO,NO> > Coordinates =
      TestHelpers::TestFactory<SC,LO,GO,NO>::BuildGeoCoordinates(numDimensions, gNodesPerDir,
                                                                 lNodesPerDir, meshData,
                                                                 meshLayout);

    Teuchos::ParameterList matrixList;
    matrixList.set("nx", gNodesPerDir[0]);
    matrixList.set("matrixType","Laplace1D");
    RCP<Galeri::Xpetra::Problem<Map,CrsMatrixWrap,MultiVector> > Pr = Galeri::Xpetra::
      BuildProblem<SC,LO,GO,Map,CrsMatrixWrap,MultiVector>("Laplace1D",
                                                           Coordinates->getMap(),
                                                           matrixList);
    RCP<Matrix> A = Pr->BuildMatrix();
    fineLevel.Request("A");
    fineLevel.Set("A", A);
    fineLevel.Set("Coordinates", Coordinates);
    fineLevel.Set("gNodesPerDim", gNodesPerDir);
    fineLevel.Set("lNodesPerDim", lNodesPerDir);

    // only one NS vector -> exercises manual orthogonalization
    LocalOrdinal NSdim = 1;
    RCP<MultiVector> nullSpace = MultiVectorFactory::Build(A->getRowMap(),NSdim);
    nullSpace->putScalar(1.0);
    fineLevel.Set("Nullspace",nullSpace);

    RCP<AmalgamationFactory> amalgFact = rcp(new AmalgamationFactory());
    RCP<CoalesceDropFactory> dropFact = rcp(new CoalesceDropFactory());
    dropFact->SetFactory("UnAmalgamationInfo", amalgFact);
    RCP<StructuredAggregationFactory> StructuredAggFact = rcp(new StructuredAggregationFactory());
    StructuredAggFact->SetFactory("Graph", dropFact);
    StructuredAggFact->SetParameter("aggregation: mesh layout",
                                    Teuchos::ParameterEntry(meshLayout));
    StructuredAggFact->SetParameter("aggregation: number of spatial dimensions",
                                    Teuchos::ParameterEntry(numDimensions));
    StructuredAggFact->SetParameter("aggregation: coarsening order",
                                    Teuchos::ParameterEntry(0));
    StructuredAggFact->SetParameter("aggregation: coarsening rate",
                                    Teuchos::ParameterEntry(std::string("{3}")));

    RCP<CoarseMapFactory> coarseMapFact = rcp(new CoarseMapFactory());
    coarseMapFact->SetFactory("Aggregates", StructuredAggFact);
    RCP<TentativePFactory> TentativePFact = rcp(new TentativePFactory());
    TentativePFact->SetFactory("Aggregates", StructuredAggFact);
    TentativePFact->SetFactory("UnAmalgamationInfo", amalgFact);
    TentativePFact->SetFactory("CoarseMap", coarseMapFact);

    coarseLevel.Request("P",TentativePFact.get());  // request Ptent
    coarseLevel.Request("Nullspace",TentativePFact.get());
    coarseLevel.Request(*TentativePFact);
    TentativePFact->Build(fineLevel,coarseLevel);

    RCP<Matrix> Ptent;
    coarseLevel.Get("P",Ptent,TentativePFact.get());

    RCP<MultiVector> coarseNullSpace = coarseLevel.Get<RCP<MultiVector> >("Nullspace",TentativePFact.get());

    coarseLevel.Release("P",TentativePFact.get()); // release Ptent
    coarseLevel.Release("Nullspace",TentativePFact.get());

    // check normalization and orthogonality of prolongator columns
    Teuchos::RCP<Xpetra::Matrix<Scalar,LocalOrdinal,GlobalOrdinal,Node> > PtentTPtent = Xpetra::MatrixMatrix<Scalar,LocalOrdinal,GlobalOrdinal,Node>::Multiply(*Ptent,true,*Ptent,false,out);
    Teuchos::RCP<Xpetra::Vector<Scalar,LocalOrdinal,GlobalOrdinal,Node> > diagVec = Xpetra::VectorFactory<Scalar,LocalOrdinal,GlobalOrdinal,Node>::Build(PtentTPtent->getRowMap());
    PtentTPtent->getLocalDiagCopy(*diagVec);
    if (TST::name().find("complex") == std::string::npos) //skip check for Scalar=complex
      TEST_FLOATING_EQUALITY(diagVec->norm1(), Teuchos::as<double>(diagVec->getGlobalLength()), 1e-12);
    TEST_FLOATING_EQUALITY(diagVec->normInf(), 1.0,  1e-12);
    TEST_EQUALITY(PtentTPtent->getGlobalNumEntries(), diagVec->getGlobalLength());

  } // GlobalLexiTentative1D

  TEUCHOS_UNIT_TEST_TEMPLATE_4_DECL(StructuredAggregation, GlobalLexiTentative2D, Scalar, LocalOrdinal, GlobalOrdinal, Node)
  {
#   include "MueLu_UseShortNames.hpp"
    MUELU_TESTING_SET_OSTREAM;
    MUELU_TESTING_LIMIT_SCOPE(Scalar,GlobalOrdinal,Node);

    typedef Teuchos::ScalarTraits<Scalar> TST;
    typedef TestHelpers::TestFactory<Scalar, LocalOrdinal, GlobalOrdinal, Node> test_factory;

    out << "version: " << MueLu::Version() << std::endl;

    Level fineLevel, coarseLevel;
    test_factory::createTwoLevelHierarchy(fineLevel, coarseLevel);
    fineLevel.SetFactoryManager(Teuchos::null);  // factory manager is not used on this test
    coarseLevel.SetFactoryManager(Teuchos::null);

    // Set global geometric data
    const std::string meshLayout = "Global Lexicographic";
    LO numDimensions = 2;
    Array<GO> meshData;
    Array<LO> lNodesPerDir(3);
    Array<GO> gNodesPerDir(3);
    for(int dim = 0; dim < 3; ++dim) {
      if(dim < numDimensions) {
        gNodesPerDir[dim] = 12;
      } else {
        gNodesPerDir[dim] = 1;
      }
    }

    RCP<const Xpetra::MultiVector<double,LO,GO,NO> > Coordinates =
      TestHelpers::TestFactory<SC,LO,GO,NO>::BuildGeoCoordinates(numDimensions, gNodesPerDir,
                                                                 lNodesPerDir, meshData,
                                                                 meshLayout);

    Teuchos::ParameterList matrixList;
    matrixList.set("nx", gNodesPerDir[0]);
    matrixList.set("matrixType","Laplace1D");
    RCP<Galeri::Xpetra::Problem<Map,CrsMatrixWrap,MultiVector> > Pr = Galeri::Xpetra::
      BuildProblem<SC,LO,GO,Map,CrsMatrixWrap,MultiVector>("Laplace2D",
                                                           Coordinates->getMap(),
                                                           matrixList);
    RCP<Matrix> A = Pr->BuildMatrix();
    fineLevel.Request("A");
    fineLevel.Set("A", A);
    fineLevel.Set("Coordinates", Coordinates);
    fineLevel.Set("gNodesPerDim", gNodesPerDir);
    fineLevel.Set("lNodesPerDim", lNodesPerDir);

    // only one NS vector -> exercises manual orthogonalization
    LocalOrdinal NSdim = 1;
    RCP<MultiVector> nullSpace = MultiVectorFactory::Build(A->getRowMap(),NSdim);
    nullSpace->putScalar(1.0);
    fineLevel.Set("Nullspace",nullSpace);

    RCP<AmalgamationFactory> amalgFact = rcp(new AmalgamationFactory());
    RCP<CoalesceDropFactory> dropFact = rcp(new CoalesceDropFactory());
    dropFact->SetFactory("UnAmalgamationInfo", amalgFact);
    RCP<StructuredAggregationFactory> StructuredAggFact = rcp(new StructuredAggregationFactory());
    StructuredAggFact->SetFactory("Graph", dropFact);
    StructuredAggFact->SetParameter("aggregation: mesh layout",
                                    Teuchos::ParameterEntry(meshLayout));
    StructuredAggFact->SetParameter("aggregation: number of spatial dimensions",
                                    Teuchos::ParameterEntry(numDimensions));
    StructuredAggFact->SetParameter("aggregation: coarsening order",
                                    Teuchos::ParameterEntry(0));
    StructuredAggFact->SetParameter("aggregation: coarsening rate",
                                    Teuchos::ParameterEntry(std::string("{3}")));

    RCP<CoarseMapFactory> coarseMapFact = rcp(new CoarseMapFactory());
    coarseMapFact->SetFactory("Aggregates", StructuredAggFact);
    RCP<TentativePFactory> TentativePFact = rcp(new TentativePFactory());
    TentativePFact->SetFactory("Aggregates", StructuredAggFact);
    TentativePFact->SetFactory("UnAmalgamationInfo", amalgFact);
    TentativePFact->SetFactory("CoarseMap", coarseMapFact);

    coarseLevel.Request("P",TentativePFact.get());  // request Ptent
    coarseLevel.Request("Nullspace",TentativePFact.get());
    coarseLevel.Request(*TentativePFact);
    TentativePFact->Build(fineLevel,coarseLevel);

    RCP<Matrix> Ptent;
    coarseLevel.Get("P",Ptent,TentativePFact.get());

    RCP<MultiVector> coarseNullSpace = coarseLevel.Get<RCP<MultiVector> >("Nullspace",TentativePFact.get());

    coarseLevel.Release("P",TentativePFact.get()); // release Ptent
    coarseLevel.Release("Nullspace",TentativePFact.get());

    // check normalization and orthogonality of prolongator columns
    Teuchos::RCP<Xpetra::Matrix<Scalar,LocalOrdinal,GlobalOrdinal,Node> > PtentTPtent = Xpetra::MatrixMatrix<Scalar,LocalOrdinal,GlobalOrdinal,Node>::Multiply(*Ptent,true,*Ptent,false,out);
    Teuchos::RCP<Xpetra::Vector<Scalar,LocalOrdinal,GlobalOrdinal,Node> > diagVec = Xpetra::VectorFactory<Scalar,LocalOrdinal,GlobalOrdinal,Node>::Build(PtentTPtent->getRowMap());
    PtentTPtent->getLocalDiagCopy(*diagVec);
    if (TST::name().find("complex") == std::string::npos) //skip check for Scalar=complex
      TEST_FLOATING_EQUALITY(diagVec->norm1(), Teuchos::as<double>(diagVec->getGlobalLength()), 1e-12);
    TEST_FLOATING_EQUALITY(diagVec->normInf(), 1.0,  1e-12);
    TEST_EQUALITY(PtentTPtent->getGlobalNumEntries(), diagVec->getGlobalLength());

  } // GlobalLexiTentative2D

  TEUCHOS_UNIT_TEST_TEMPLATE_4_DECL(StructuredAggregation, GlobalLexiTentative3D, Scalar, LocalOrdinal, GlobalOrdinal, Node)
  {
#   include "MueLu_UseShortNames.hpp"
    MUELU_TESTING_SET_OSTREAM;
    MUELU_TESTING_LIMIT_SCOPE(Scalar,GlobalOrdinal,Node);

    typedef Teuchos::ScalarTraits<Scalar> TST;
    typedef TestHelpers::TestFactory<Scalar, LocalOrdinal, GlobalOrdinal, Node> test_factory;

    out << "version: " << MueLu::Version() << std::endl;

    Level fineLevel, coarseLevel;
    test_factory::createTwoLevelHierarchy(fineLevel, coarseLevel);
    fineLevel.SetFactoryManager(Teuchos::null);  // factory manager is not used on this test
    coarseLevel.SetFactoryManager(Teuchos::null);

    // Set global geometric data
    const std::string meshLayout = "Global Lexicographic";
    LO numDimensions = 3;
    Array<GO> meshData;
    Array<LO> lNodesPerDir(3);
    Array<GO> gNodesPerDir(3);
    for(int dim = 0; dim < 3; ++dim) {
      if(dim < numDimensions) {
        gNodesPerDir[dim] = 6;
      } else {
        gNodesPerDir[dim] = 1;
      }
    }

    RCP<const Xpetra::MultiVector<double,LO,GO,NO> > Coordinates =
      TestHelpers::TestFactory<SC,LO,GO,NO>::BuildGeoCoordinates(numDimensions, gNodesPerDir,
                                                                 lNodesPerDir, meshData,
                                                                 meshLayout);

    Teuchos::ParameterList matrixList;
    matrixList.set("nx", gNodesPerDir[0]);
    matrixList.set("matrixType","Laplace1D");
    RCP<Galeri::Xpetra::Problem<Map,CrsMatrixWrap,MultiVector> > Pr = Galeri::Xpetra::
      BuildProblem<SC,LO,GO,Map,CrsMatrixWrap,MultiVector>("Laplace3D",
                                                           Coordinates->getMap(),
                                                           matrixList);
    RCP<Matrix> A = Pr->BuildMatrix();
    fineLevel.Request("A");
    fineLevel.Set("A", A);
    fineLevel.Set("Coordinates", Coordinates);
    fineLevel.Set("gNodesPerDim", gNodesPerDir);
    fineLevel.Set("lNodesPerDim", lNodesPerDir);

    // only one NS vector -> exercises manual orthogonalization
    LocalOrdinal NSdim = 1;
    RCP<MultiVector> nullSpace = MultiVectorFactory::Build(A->getRowMap(),NSdim);
    nullSpace->putScalar(1.0);
    fineLevel.Set("Nullspace",nullSpace);

    RCP<AmalgamationFactory> amalgFact = rcp(new AmalgamationFactory());
    RCP<CoalesceDropFactory> dropFact = rcp(new CoalesceDropFactory());
    dropFact->SetFactory("UnAmalgamationInfo", amalgFact);
    RCP<StructuredAggregationFactory> StructuredAggFact = rcp(new StructuredAggregationFactory());
    StructuredAggFact->SetFactory("Graph", dropFact);
    StructuredAggFact->SetParameter("aggregation: mesh layout",
                                    Teuchos::ParameterEntry(meshLayout));
    StructuredAggFact->SetParameter("aggregation: number of spatial dimensions",
                                    Teuchos::ParameterEntry(numDimensions));
    StructuredAggFact->SetParameter("aggregation: coarsening order",
                                    Teuchos::ParameterEntry(0));
    StructuredAggFact->SetParameter("aggregation: coarsening rate",
                                    Teuchos::ParameterEntry(std::string("{3}")));

    RCP<CoarseMapFactory> coarseMapFact = rcp(new CoarseMapFactory());
    coarseMapFact->SetFactory("Aggregates", StructuredAggFact);
    RCP<TentativePFactory> TentativePFact = rcp(new TentativePFactory());
    TentativePFact->SetFactory("Aggregates", StructuredAggFact);
    TentativePFact->SetFactory("UnAmalgamationInfo", amalgFact);
    TentativePFact->SetFactory("CoarseMap", coarseMapFact);

    coarseLevel.Request("P",TentativePFact.get());  // request Ptent
    coarseLevel.Request("Nullspace",TentativePFact.get());
    coarseLevel.Request(*TentativePFact);
    TentativePFact->Build(fineLevel,coarseLevel);

    RCP<Matrix> Ptent;
    coarseLevel.Get("P",Ptent,TentativePFact.get());

    RCP<MultiVector> coarseNullSpace = coarseLevel.Get<RCP<MultiVector> >("Nullspace",TentativePFact.get());

    coarseLevel.Release("P",TentativePFact.get()); // release Ptent
    coarseLevel.Release("Nullspace",TentativePFact.get());

    // check normalization and orthogonality of prolongator columns
    Teuchos::RCP<Xpetra::Matrix<Scalar,LocalOrdinal,GlobalOrdinal,Node> > PtentTPtent = Xpetra::MatrixMatrix<Scalar,LocalOrdinal,GlobalOrdinal,Node>::Multiply(*Ptent,true,*Ptent,false,out);
    Teuchos::RCP<Xpetra::Vector<Scalar,LocalOrdinal,GlobalOrdinal,Node> > diagVec = Xpetra::VectorFactory<Scalar,LocalOrdinal,GlobalOrdinal,Node>::Build(PtentTPtent->getRowMap());
    PtentTPtent->getLocalDiagCopy(*diagVec);
    if (TST::name().find("complex") == std::string::npos) //skip check for Scalar=complex
      TEST_FLOATING_EQUALITY(diagVec->norm1(), Teuchos::as<double>(diagVec->getGlobalLength()), 1e-12);
    TEST_FLOATING_EQUALITY(diagVec->normInf(), 1.0,  1e-12);
    TEST_EQUALITY(PtentTPtent->getGlobalNumEntries(), diagVec->getGlobalLength());

  } // GlobalLexiTentative3D

  TEUCHOS_UNIT_TEST_TEMPLATE_4_DECL(StructuredAggregation, LocalLexiTentative1D, Scalar, LocalOrdinal, GlobalOrdinal, Node)
  {
#   include "MueLu_UseShortNames.hpp"
    MUELU_TESTING_SET_OSTREAM;
    MUELU_TESTING_LIMIT_SCOPE(Scalar,GlobalOrdinal,Node);

    typedef Teuchos::ScalarTraits<Scalar> TST;
    typedef TestHelpers::TestFactory<Scalar, LocalOrdinal, GlobalOrdinal, Node> test_factory;

    out << "version: " << MueLu::Version() << std::endl;

    Level fineLevel, coarseLevel;
    test_factory::createTwoLevelHierarchy(fineLevel, coarseLevel);
    fineLevel.SetFactoryManager(Teuchos::null);  // factory manager is not used on this test
    coarseLevel.SetFactoryManager(Teuchos::null);

    // Set global geometric data
    const std::string meshLayout = "Local Lexicographic";
    LO numDimensions = 1;
    Array<GO> meshData;
    Array<LO> lNodesPerDir(3);
    Array<GO> gNodesPerDir(3);
    for(int dim = 0; dim < 3; ++dim) {
      if(dim < numDimensions) {
        // Use more nodes in 1D to have a reasonable number of nodes per procs
        gNodesPerDir[dim] = 20;
      } else {
        gNodesPerDir[dim] = 1;
      }
    }

    RCP<const Xpetra::MultiVector<double,LO,GO,NO> > Coordinates =
      TestHelpers::TestFactory<SC,LO,GO,NO>::BuildGeoCoordinates(numDimensions, gNodesPerDir,
                                                                 lNodesPerDir, meshData,
                                                                 meshLayout);

    Teuchos::ParameterList matrixList;
    matrixList.set("nx", gNodesPerDir[0]);
    matrixList.set("matrixType","Laplace1D");
    RCP<Galeri::Xpetra::Problem<Map,CrsMatrixWrap,MultiVector> > Pr = Galeri::Xpetra::
      BuildProblem<SC,LO,GO,Map,CrsMatrixWrap,MultiVector>("Laplace1D",
                                                           Coordinates->getMap(),
                                                           matrixList);
    RCP<Matrix> A = Pr->BuildMatrix();
    fineLevel.Request("A");
    fineLevel.Set("A", A);
    fineLevel.Set("Coordinates", Coordinates);
    fineLevel.Set("gNodesPerDim", gNodesPerDir);
    fineLevel.Set("lNodesPerDim", lNodesPerDir);
    fineLevel.Set("aggregation: mesh data", meshData);

    // only one NS vector -> exercises manual orthogonalization
    LocalOrdinal NSdim = 1;
    RCP<MultiVector> nullSpace = MultiVectorFactory::Build(A->getRowMap(),NSdim);
    nullSpace->putScalar(1.0);
    fineLevel.Set("Nullspace",nullSpace);

    RCP<AmalgamationFactory> amalgFact = rcp(new AmalgamationFactory());
    RCP<CoalesceDropFactory> dropFact = rcp(new CoalesceDropFactory());
    dropFact->SetFactory("UnAmalgamationInfo", amalgFact);
    RCP<StructuredAggregationFactory> StructuredAggFact = rcp(new StructuredAggregationFactory());
    StructuredAggFact->SetFactory("Graph", dropFact);
    StructuredAggFact->SetParameter("aggregation: mesh layout",
                                    Teuchos::ParameterEntry(meshLayout));
    StructuredAggFact->SetParameter("aggregation: number of spatial dimensions",
                                    Teuchos::ParameterEntry(numDimensions));
    StructuredAggFact->SetParameter("aggregation: coarsening order",
                                    Teuchos::ParameterEntry(0));
    StructuredAggFact->SetParameter("aggregation: coarsening rate",
                                    Teuchos::ParameterEntry(std::string("{3}")));

    RCP<CoarseMapFactory> coarseMapFact = rcp(new CoarseMapFactory());
    coarseMapFact->SetFactory("Aggregates", StructuredAggFact);
    RCP<TentativePFactory> TentativePFact = rcp(new TentativePFactory());
    TentativePFact->SetFactory("Aggregates", StructuredAggFact);
    TentativePFact->SetFactory("UnAmalgamationInfo", amalgFact);
    TentativePFact->SetFactory("CoarseMap", coarseMapFact);

    coarseLevel.Request("P",TentativePFact.get());  // request Ptent
    coarseLevel.Request("Nullspace",TentativePFact.get());
    coarseLevel.Request(*TentativePFact);
    TentativePFact->Build(fineLevel,coarseLevel);

    RCP<Matrix> Ptent;
    coarseLevel.Get("P",Ptent,TentativePFact.get());

    RCP<MultiVector> coarseNullSpace = coarseLevel.Get<RCP<MultiVector> >("Nullspace",TentativePFact.get());

    coarseLevel.Release("P",TentativePFact.get()); // release Ptent
    coarseLevel.Release("Nullspace",TentativePFact.get());

    // check normalization and orthogonality of prolongator columns
    Teuchos::RCP<Xpetra::Matrix<Scalar,LocalOrdinal,GlobalOrdinal,Node> > PtentTPtent = Xpetra::MatrixMatrix<Scalar,LocalOrdinal,GlobalOrdinal,Node>::Multiply(*Ptent,true,*Ptent,false,out);
    Teuchos::RCP<Xpetra::Vector<Scalar,LocalOrdinal,GlobalOrdinal,Node> > diagVec = Xpetra::VectorFactory<Scalar,LocalOrdinal,GlobalOrdinal,Node>::Build(PtentTPtent->getRowMap());
    PtentTPtent->getLocalDiagCopy(*diagVec);
    if (TST::name().find("complex") == std::string::npos) //skip check for Scalar=complex
      TEST_FLOATING_EQUALITY(diagVec->norm1(), Teuchos::as<double>(diagVec->getGlobalLength()), 1e-12);
    TEST_FLOATING_EQUALITY(diagVec->normInf(), 1.0,  1e-12);
    TEST_EQUALITY(PtentTPtent->getGlobalNumEntries(), diagVec->getGlobalLength());

  } // LocalLexiTentative1D

  TEUCHOS_UNIT_TEST_TEMPLATE_4_DECL(StructuredAggregation, LocalLexiTentative2D, Scalar, LocalOrdinal, GlobalOrdinal, Node)
  {
#   include "MueLu_UseShortNames.hpp"
    MUELU_TESTING_SET_OSTREAM;
    MUELU_TESTING_LIMIT_SCOPE(Scalar,GlobalOrdinal,Node);

    typedef Teuchos::ScalarTraits<Scalar> TST;
    typedef TestHelpers::TestFactory<Scalar, LocalOrdinal, GlobalOrdinal, Node> test_factory;

    out << "version: " << MueLu::Version() << std::endl;

    Level fineLevel, coarseLevel;
    test_factory::createTwoLevelHierarchy(fineLevel, coarseLevel);
    fineLevel.SetFactoryManager(Teuchos::null);  // factory manager is not used on this test
    coarseLevel.SetFactoryManager(Teuchos::null);

    // Set global geometric data
    const std::string meshLayout = "Local Lexicographic";
    LO numDimensions = 2;
    Array<GO> meshData;
    Array<LO> lNodesPerDir(3);
    Array<GO> gNodesPerDir(3);
    for(int dim = 0; dim < 3; ++dim) {
      if(dim < numDimensions) {
        // Use more nodes in 1D to have a reasonable number of nodes per procs
        gNodesPerDir[dim] = 12;
      } else {
        gNodesPerDir[dim] = 1;
      }
    }

    RCP<const Xpetra::MultiVector<double,LO,GO,NO> > Coordinates =
      TestHelpers::TestFactory<SC,LO,GO,NO>::BuildGeoCoordinates(numDimensions, gNodesPerDir,
                                                                 lNodesPerDir, meshData,
                                                                 meshLayout);

    Teuchos::ParameterList matrixList;
    matrixList.set("nx", gNodesPerDir[0]);
    matrixList.set("matrixType","Laplace1D");
    RCP<Galeri::Xpetra::Problem<Map,CrsMatrixWrap,MultiVector> > Pr = Galeri::Xpetra::
      BuildProblem<SC,LO,GO,Map,CrsMatrixWrap,MultiVector>("Laplace2D",
                                                           Coordinates->getMap(),
                                                           matrixList);
    RCP<Matrix> A = Pr->BuildMatrix();
    fineLevel.Request("A");
    fineLevel.Set("A", A);
    fineLevel.Set("Coordinates", Coordinates);
    fineLevel.Set("gNodesPerDim", gNodesPerDir);
    fineLevel.Set("lNodesPerDim", lNodesPerDir);
    fineLevel.Set("aggregation: mesh data", meshData);

    // only one NS vector -> exercises manual orthogonalization
    LocalOrdinal NSdim = 1;
    RCP<MultiVector> nullSpace = MultiVectorFactory::Build(A->getRowMap(),NSdim);
    nullSpace->putScalar(1.0);
    fineLevel.Set("Nullspace",nullSpace);

    RCP<AmalgamationFactory> amalgFact = rcp(new AmalgamationFactory());
    RCP<CoalesceDropFactory> dropFact = rcp(new CoalesceDropFactory());
    dropFact->SetFactory("UnAmalgamationInfo", amalgFact);
    RCP<StructuredAggregationFactory> StructuredAggFact = rcp(new StructuredAggregationFactory());
    StructuredAggFact->SetFactory("Graph", dropFact);
    StructuredAggFact->SetParameter("aggregation: mesh layout",
                                    Teuchos::ParameterEntry(meshLayout));
    StructuredAggFact->SetParameter("aggregation: number of spatial dimensions",
                                    Teuchos::ParameterEntry(numDimensions));
    StructuredAggFact->SetParameter("aggregation: coarsening order",
                                    Teuchos::ParameterEntry(0));
    StructuredAggFact->SetParameter("aggregation: coarsening rate",
                                    Teuchos::ParameterEntry(std::string("{3}")));

    RCP<CoarseMapFactory> coarseMapFact = rcp(new CoarseMapFactory());
    coarseMapFact->SetFactory("Aggregates", StructuredAggFact);
    RCP<TentativePFactory> TentativePFact = rcp(new TentativePFactory());
    TentativePFact->SetFactory("Aggregates", StructuredAggFact);
    TentativePFact->SetFactory("UnAmalgamationInfo", amalgFact);
    TentativePFact->SetFactory("CoarseMap", coarseMapFact);

    coarseLevel.Request("P",TentativePFact.get());  // request Ptent
    coarseLevel.Request("Nullspace",TentativePFact.get());
    coarseLevel.Request(*TentativePFact);
    TentativePFact->Build(fineLevel,coarseLevel);

    RCP<Matrix> Ptent;
    coarseLevel.Get("P",Ptent,TentativePFact.get());

    RCP<MultiVector> coarseNullSpace = coarseLevel.Get<RCP<MultiVector> >("Nullspace",TentativePFact.get());

    coarseLevel.Release("P",TentativePFact.get()); // release Ptent
    coarseLevel.Release("Nullspace",TentativePFact.get());

    // check normalization and orthogonality of prolongator columns
    Teuchos::RCP<Xpetra::Matrix<Scalar,LocalOrdinal,GlobalOrdinal,Node> > PtentTPtent = Xpetra::MatrixMatrix<Scalar,LocalOrdinal,GlobalOrdinal,Node>::Multiply(*Ptent,true,*Ptent,false,out);
    Teuchos::RCP<Xpetra::Vector<Scalar,LocalOrdinal,GlobalOrdinal,Node> > diagVec = Xpetra::VectorFactory<Scalar,LocalOrdinal,GlobalOrdinal,Node>::Build(PtentTPtent->getRowMap());
    PtentTPtent->getLocalDiagCopy(*diagVec);
    if (TST::name().find("complex") == std::string::npos) //skip check for Scalar=complex
      TEST_FLOATING_EQUALITY(diagVec->norm1(), Teuchos::as<double>(diagVec->getGlobalLength()), 1e-12);
    TEST_FLOATING_EQUALITY(diagVec->normInf(), 1.0,  1e-12);
    TEST_EQUALITY(PtentTPtent->getGlobalNumEntries(), diagVec->getGlobalLength());

  } // LocalLexiTentative2D

  TEUCHOS_UNIT_TEST_TEMPLATE_4_DECL(StructuredAggregation, LocalLexiTentative3D, Scalar, LocalOrdinal, GlobalOrdinal, Node)
  {
#   include "MueLu_UseShortNames.hpp"
    MUELU_TESTING_SET_OSTREAM;
    MUELU_TESTING_LIMIT_SCOPE(Scalar,GlobalOrdinal,Node);

    typedef Teuchos::ScalarTraits<Scalar> TST;
    typedef TestHelpers::TestFactory<Scalar, LocalOrdinal, GlobalOrdinal, Node> test_factory;

    out << "version: " << MueLu::Version() << std::endl;

    Level fineLevel, coarseLevel;
    test_factory::createTwoLevelHierarchy(fineLevel, coarseLevel);
    fineLevel.SetFactoryManager(Teuchos::null);  // factory manager is not used on this test
    coarseLevel.SetFactoryManager(Teuchos::null);

    // Set global geometric data
    const std::string meshLayout = "Local Lexicographic";
    LO numDimensions = 3;
    Array<GO> meshData;
    Array<LO> lNodesPerDir(3);
    Array<GO> gNodesPerDir(3);
    for(int dim = 0; dim < 3; ++dim) {
      if(dim < numDimensions) {
        // Use more nodes in 1D to have a reasonable number of nodes per procs
        gNodesPerDir[dim] = 6;
      } else {
        gNodesPerDir[dim] = 1;
      }
    }

    RCP<const Xpetra::MultiVector<double,LO,GO,NO> > Coordinates =
      TestHelpers::TestFactory<SC,LO,GO,NO>::BuildGeoCoordinates(numDimensions, gNodesPerDir,
                                                                 lNodesPerDir, meshData,
                                                                 meshLayout);

    Teuchos::ParameterList matrixList;
    matrixList.set("nx", gNodesPerDir[0]);
    matrixList.set("matrixType","Laplace1D");
    RCP<Galeri::Xpetra::Problem<Map,CrsMatrixWrap,MultiVector> > Pr = Galeri::Xpetra::
      BuildProblem<SC,LO,GO,Map,CrsMatrixWrap,MultiVector>("Laplace3D",
                                                           Coordinates->getMap(),
                                                           matrixList);
    RCP<Matrix> A = Pr->BuildMatrix();
    fineLevel.Request("A");
    fineLevel.Set("A", A);
    fineLevel.Set("Coordinates", Coordinates);
    fineLevel.Set("gNodesPerDim", gNodesPerDir);
    fineLevel.Set("lNodesPerDim", lNodesPerDir);
    fineLevel.Set("aggregation: mesh data", meshData);

    // only one NS vector -> exercises manual orthogonalization
    LocalOrdinal NSdim = 1;
    RCP<MultiVector> nullSpace = MultiVectorFactory::Build(A->getRowMap(),NSdim);
    nullSpace->putScalar(1.0);
    fineLevel.Set("Nullspace",nullSpace);


    RCP<AmalgamationFactory> amalgFact = rcp(new AmalgamationFactory());
    RCP<CoalesceDropFactory> dropFact = rcp(new CoalesceDropFactory());
    dropFact->SetFactory("UnAmalgamationInfo", amalgFact);
    RCP<StructuredAggregationFactory> StructuredAggFact = rcp(new StructuredAggregationFactory());
    StructuredAggFact->SetFactory("Graph", dropFact);
    StructuredAggFact->SetParameter("aggregation: mesh layout",
                                    Teuchos::ParameterEntry(meshLayout));
    StructuredAggFact->SetParameter("aggregation: number of spatial dimensions",
                                    Teuchos::ParameterEntry(numDimensions));
    StructuredAggFact->SetParameter("aggregation: coarsening order",
                                    Teuchos::ParameterEntry(0));
    StructuredAggFact->SetParameter("aggregation: coarsening rate",
                                    Teuchos::ParameterEntry(std::string("{3}")));

    RCP<CoarseMapFactory> coarseMapFact = rcp(new CoarseMapFactory());
    coarseMapFact->SetFactory("Aggregates", StructuredAggFact);
    RCP<TentativePFactory> TentativePFact = rcp(new TentativePFactory());
    TentativePFact->SetFactory("Aggregates", StructuredAggFact);
    TentativePFact->SetFactory("UnAmalgamationInfo", amalgFact);
    TentativePFact->SetFactory("CoarseMap", coarseMapFact);

    coarseLevel.Request("P",TentativePFact.get());  // request Ptent
    coarseLevel.Request("Nullspace",TentativePFact.get());
    coarseLevel.Request(*TentativePFact);
    TentativePFact->Build(fineLevel,coarseLevel);

    RCP<Matrix> Ptent;
    coarseLevel.Get("P",Ptent,TentativePFact.get());

    RCP<MultiVector> coarseNullSpace = coarseLevel.Get<RCP<MultiVector> >("Nullspace",TentativePFact.get());

    coarseLevel.Release("P",TentativePFact.get()); // release Ptent
    coarseLevel.Release("Nullspace",TentativePFact.get());

    // check normalization and orthogonality of prolongator columns
    Teuchos::RCP<Xpetra::Matrix<Scalar,LocalOrdinal,GlobalOrdinal,Node> > PtentTPtent = Xpetra::MatrixMatrix<Scalar,LocalOrdinal,GlobalOrdinal,Node>::Multiply(*Ptent,true,*Ptent,false,out);
    Teuchos::RCP<Xpetra::Vector<Scalar,LocalOrdinal,GlobalOrdinal,Node> > diagVec = Xpetra::VectorFactory<Scalar,LocalOrdinal,GlobalOrdinal,Node>::Build(PtentTPtent->getRowMap());
    PtentTPtent->getLocalDiagCopy(*diagVec);
    if (TST::name().find("complex") == std::string::npos) //skip check for Scalar=complex
      TEST_FLOATING_EQUALITY(diagVec->norm1(), Teuchos::as<double>(diagVec->getGlobalLength()), 1e-12);
    TEST_FLOATING_EQUALITY(diagVec->normInf(), 1.0,  1e-12);
    TEST_EQUALITY(PtentTPtent->getGlobalNumEntries(), diagVec->getGlobalLength());

  } // LocalLexiTentative3D

#  define MUELU_ETI_GROUP(Scalar, LO, GO, Node) \
      TEUCHOS_UNIT_TEST_TEMPLATE_4_INSTANT(StructuredAggregation,CreateGlobalLexicographicIndexManager,Scalar,LO,GO,Node) \
      TEUCHOS_UNIT_TEST_TEMPLATE_4_INSTANT(StructuredAggregation,CreateLocalLexicographicIndexManager,Scalar,LO,GO,Node) \
      TEUCHOS_UNIT_TEST_TEMPLATE_4_INSTANT(StructuredAggregation,GlobalLexiTentative1D,Scalar,LO,GO,Node) \
      TEUCHOS_UNIT_TEST_TEMPLATE_4_INSTANT(StructuredAggregation,GlobalLexiTentative2D,Scalar,LO,GO,Node) \
      TEUCHOS_UNIT_TEST_TEMPLATE_4_INSTANT(StructuredAggregation,GlobalLexiTentative3D,Scalar,LO,GO,Node) \
      TEUCHOS_UNIT_TEST_TEMPLATE_4_INSTANT(StructuredAggregation,LocalLexiTentative1D,Scalar,LO,GO,Node) \
      TEUCHOS_UNIT_TEST_TEMPLATE_4_INSTANT(StructuredAggregation,LocalLexiTentative2D,Scalar,LO,GO,Node) \
      TEUCHOS_UNIT_TEST_TEMPLATE_4_INSTANT(StructuredAggregation,LocalLexiTentative3D,Scalar,LO,GO,Node)

#include <MueLu_ETI_4arg.hpp>


} // namespace MueLuTests
