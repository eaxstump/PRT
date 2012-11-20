classdef prtRvGmmApproxDp < prtRv
    % prtRvGmmApproxDp - Approx Dirichlet Process Gaussian Mixture Model 
    %       Random Variable
    %
    %   RV = prtRvGmmApproxDp creates a prtRvGmmApproxDp object with empty
    %   empty parameters. These parameters can be set by calling the MLE()
    %   or RUN() methods. A prtRvGmmApproxDp is a mixture of multi-variance
    %   normal random variables that approximates a Dirichlet process
    %   mixture model. The DP approximation is calculated using the Mean
    %   Shift algorithm to estimate the number of and approximate value of
    %   the means of each cluster.
    %
    %   RV = prtRvGmmApproxDp(PROPERTY1, VALUE1,...) creates a
    %   prtRvGmmApproxDp object RV with properties as specified by
    %   PROPERTY/VALUE pairs.
    %
    %   A prtRvGmmApproxDp object inherits all properties from the prtRv class.
    %   In addition, it has the following properties:
    %
    %   nMaxComponents      - A positive integer specifiying the maximum
    %                         number of MVN components in the mixture.
    %                         When nMaxComponents is empty the number of
    %                         observations in the training dataset is used.
    %                         The default value is empty. 
    %   covarianceStructure - The covariance structure applied to each of
    %                         the prtRvMvn objects in the mixture. See
    %                         prtRvMvn.
    %   meanShiftMembershipDistance - The membershipDistance used by the
    %                                 mean shift algorithm to determine the
    %                                 number of clusters.
    %   components          - An array of prtRvMvn objects.
    %   mixingProportions   - A discrete probability vector, representing
    %                         the probability of each component in the
    %                         mixture.
    %
    %  A prtRvGmmApproxDp object inherits all methods from the prtRv class.
    %  The MLE method can be used to estimate the distribution parameters
    %  from data.
    %
    %  Examples:
    %       ds = prtDataGenOldFaithful;      % Load a data set
    %       rv = prtRvGmmApproxDp('nMaxComponents',20); 
    %       rv = mle(rv,ds);                 % Compute the ML estimate
    %       plotPdf(rv);                     % Plot the estimated PDF
    %       hold on;
    %       plot(ds);                        % Overlay the original data   
    %
    %   See also: prtRv, prtRvMvn, prtRvMultinomial, prtRvUniform,
    %             prtRvUniformImproper, prtRvVq, prtRvGmm
    
    properties (SetAccess = private)
        name = 'Approx DP Gaussian Mixture Model';
        nameAbbreviation = 'RVADPGMM';
    end
    
    properties (SetAccess = protected)
        isSupervised = false;
        isCrossValidateValid = true;
    end    
    
    properties
        meanShiftMembershipDistance = 1;
        minimumStandardDeviation = eps;
    end
    properties (Dependent = true)
        nComponents            % The number of components contained in the mixture
        nMaxComponents         % The maximum number of components
        covarianceStructure    % The covariance structure
        components             % The mixture components
        mixingProportions      % The mixing proportions
    end
    
    properties (SetAccess = 'private', GetAccess = 'private', Hidden=true)
        nComponentsDepHelp = [];
        nMaxComponentsDepHelp = [];
        covarianceStructureDepHelp = 'full'; 
    end
    
    properties (SetAccess='private', Hidden=true)
        mixtureRv = prtRvMixture('components',prtRvMvn('covarianceStructure','full'),'mixingProportions',prtRvMultinomial('probabilities',1));
    end
    
    properties (Hidden = true, Dependent = true)
        nDimensions
    end
    
    methods
        function R = prtRvGmmApproxDp(varargin)
            R = constructorInputParse(R,varargin{:});
        end
    end
    
    methods
        function R = set.meanShiftMembershipDistance(R,val)
            assert(prtUtilIsPositiveScalar(val),'meanShiftMembershipDistance must be a positive integer')
            R.meanShiftMembershipDistance = val;
        end
        function R = set.minimumStandardDeviation(R,val)
            assert(prtUtilIsPositiveScalar(val),'minimumStandardDeviation must be a positive integer')
            R.minimumStandardDeviation = val;
        end
        
        function val = get.nDimensions(R)
            val = R.mixtureRv.nDimensions;
        end
        function val = get.components(R)
            val = R.mixtureRv.components;
        end
        function val = get.mixingProportions(R)
            val = R.mixtureRv.mixingProportions;
        end
        function R = set.nComponents(R,val) %#ok<MANU,INUSD>
            error('nComponents cannot be set');
        end
        function val = get.nComponents(R)
            val = R.nComponentsDepHelp;
        end
        function val = get.nComponentsDepHelp(R)
            val = R.mixtureRv.nComponents;
        end
        function R = set.nMaxComponents(R,val)
            R.nMaxComponentsDepHelp = val;
        end
        function val = get.nMaxComponents(R)
            val = R.nMaxComponentsDepHelp;
        end
        function val = get.covarianceStructure(R)
            val = R.covarianceStructureDepHelp;
        end
    end
    
	methods 
        function R = set.covarianceStructure(R,val)
            for iComp = 1:R.nComponents
                R.mixtureRv.components(iComp).covarianceStructure = val;
            end
            R.covarianceStructureDepHelp = val;
        end
        function R = set.components(R,vals)
            assert(all(isa(vals,'prtRvMvn')),'components must be of type prtRvMvn');
            
            R.mixtureRv.components = vals;
        end
        function R = set.mixingProportions(R,vals)
            R.mixtureRv.mixingProportions = vals;
        end
    end
        
    
    methods
        function R = mle(R,X)
            X = R.dataInputParse(X);
            
            if isempty(R.nMaxComponents)
                R.nMaxComponents = size(X,1);
            end
            
            dsX = prtDataSetClass(X);
            
            meanShiftAlgo = train(prtClusterMeanShift('nClusters',R.nMaxComponents,'membershipDistance',R.meanShiftMembershipDistance) + prtDecisionMap, dsX);
            clusteringDataSet = run(meanShiftAlgo, dsX);
            clusteringY = clusteringDataSet.getObservations;
            
            means = meanShiftAlgo.actionCell{1}.clusterCenters;
            nClusters = size(means,1);
            clusterCounts = histc(clusteringY,1:nClusters)';
            
            R.mixtureRv = prtRvMixture('components',repmat(prtRvMvn('covarianceStructure',R.covarianceStructure), nClusters,1),'mixingProportions',prtRvMultinomial('probabilities',clusterCounts./sum(clusterCounts)));
            for iMean = 1:nClusters
                cX = X(clusteringY==iMean,:);
                
                R.mixtureRv.components(iMean).mu = mean(cX,1);
                if size(cX,1) > (size(cX,2)+5) % 5 is rather arbitrary but it is motivated by comm Bayesian Wishart priors
                    cSigma = cov(cX);
                    cSigmaDiag = diag(cSigma);
                    badDiag = cSigmaDiag< R.minimumStandardDeviation;
                    if any(badDiag)
                        cSigmaDiag(badDiag) = R.minimumStandardDeviation;
                        cSigma(logical(eye(size(cSigma)))) = cSigmaDiag;
                    end
                    R.mixtureRv.components(iMean).sigma = cSigma;
                    
                else
                    R.mixtureRv.components(iMean).sigma = eye(size(cX,2))*R.meanShiftMembershipDistance;
                end
            end
            
            
        end
        
        function [y, componentPdf] = pdf(R,X)
            [y, componentPdf] = pdf(R.mixtureRv,X);
        end 
        
        function [logy, componentLogPdf] = logPdf(R,X)
            [logy, componentLogPdf] = logPdf(R.mixtureRv,X);
        end 
        
        function y = cdf(R,X)
            y = cdf(R.mixtureRv,X);
        end
        
        function [vals, components] = draw(R,N)
            [vals, components] = draw(R.mixtureRv,N);
        end
    end

    methods (Hidden=true)
        function [val, reasonStr] = isValid(R)
            if numel(R) > 1
                val = false(size(R));
                for iR = 1:numel(R)
                    [val(iR), reasonStr] = isValid(R(iR));
                end
                return
            end
            
            [val, reasonStr] = isValid(R.mixtureRv);
        end
        function val = plotLimits(R)
            val = plotLimits(R.mixtureRv);
        end
    end
end