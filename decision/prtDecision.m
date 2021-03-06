classdef prtDecision < prtAction
    % prtDecision Base class for sll prt decision objects
    %
    %  This is a base class from which all prt decision objects inherit. It
    %  cannot be instantiated. prtDecision objects inherit the RUN function
    %  from prtAction objects. 
    %
    % prtDecision objects accept the outputs of classifiers or clusterers
    % and return class or cluster labels.  The output of a prtDecision 
    % object's run function is always a nObservations x 1 data set where
    % the observations are integer valued and specify the hypothesized
    % class for each observation
    %
    % Decisions can be used in two ways - either as part of an algorithm:
    %
    % algo = prtClassKnn + prtDecisionBinaryMinPe;
    %
    % Or as the internalDecider object inside a prtClass object:
    %
    %  myKnn = prtClassKnn;
    %  myKnn.internalDecider = prtDecisionBinaryMinPe;
    %  myKnn = myKnn.train(dsTrain);
    % 
    % In the first case, the resulting object is a prtAlgorithm, which
    % changes the behavior of PLOT.  In the second case, the decision is
    % incorporated into the classifier, allowing the decision contours to
    % be plotted easily.
    %
    % Note that the regardless of how one uses a decider, the outputs of
    % the RUN function should be identical.
    %
    %  % Example 1:
    % 
    % % This example demonstrates use of a prtDecision object to perform
    % % class labeling as part of a prtAlgorithm
    %
    % dsTrain = prtDataGenUnimodal;
    % dsTest = prtDataGenUnimodal;
    % algo = prtClassKnn + prtDecisionBinaryMinPe;
    % algo = algo.train(dsTrain);
    % plot(algo); title('Algorithm implementation');
    % outAlgo = algo.run(dsTest);
    %
    %  % Example 2:
    % 
    %  % This example demonstrtes the use of a prtDecision objet to perform
    %  % class labeling as prtClass objects internalDecider
    %
    %  myKnn = prtClassKnn;
    %  myKnn.internalDecider = prtDecisionBinaryMinPe;
    %  myKnn = myKnn.train(dsTrain);
    %  outIntDec = myKnn.run(dsTest);
    %  figure; plot(myKnn); title('internalDecider implementation');







    properties (Dependent)
        classList
    end
    properties (Hidden)
        hiddenClassList
    end
    
    properties (SetAccess = protected)
        isSupervised = false; % False
        isCrossValidateValid = true; % True
    end
    
    methods
        function obj = prtDecision()
            % As an action subclass we must set the properties to reflect
            % our dataset requirements
            obj.classTrain = 'prtDataSetStandard';
            obj.classRun = 'prtDataSetStandard';
            obj.classRunRetained = true;
        end 
        function obj = set.classList(obj,val)
            obj.hiddenClassList = val(:);
        end
        function c = get.classList(obj)
            %             if isempty(obj.classList)
            %                 error('prtDecision field of a classifier was not set during training; please try re-training the classifier');
            %             end
            c = obj.hiddenClassList;
        end
    end
end
