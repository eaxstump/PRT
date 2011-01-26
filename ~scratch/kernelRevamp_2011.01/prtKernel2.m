classdef prtKernel2 
    %should we inherit from prtAction?
    % would simplify a ton of stuff
    %
    %
    % Sample code:
    %
    % ds1 = prtDataGenUnimodal;
    % ds2 = prtDataGenUnimodal;
    %
    % k = prtKernelRbf2;
    % k2 = k;
    % k2.sigma = 2;
    %
    % k = k.train(ds);
    % k2 = k2.train(ds);
    %
    % gram1 = k.run(ds2);
    % gram2 = k.run(ds2);
    %
    % subplot(2,2,1); imagesc(gram1.getObservations,[0 1]);
    % subplot(2,2,2); imagesc(gram2.getObservations,[0 1]);
    %
    % %%
    %
    % kCombined = k & k2;
    % kCombined = kCombined.train(ds);
    % gramCombined = kCombined.run(ds2);
    %
    % imagesc(gramCombined.getObservations);
    %
    % %%
    %
    % kCombined = prtKernelDc2 & k & k2;
    % kCombined = kCombined.train(ds);
    % [nColumns,nColumnsByKernel] = kCombined.getNumDimensions;
    %
    % %pick the DC kernel, the first k kernel, and the last k2 kernel:
    % kCombined = kCombined.retainKernelDimensions([true,true,false(1,798),true]);
    % gramCombined = kCombined.run(ds2);
    %
    % imagesc(gramCombined.getObservations);
    
    methods (Abstract)
        Obj = train(Obj,dsTrain)
        dsOut = run(Obj,dsTest)
        nDimensions = getNumDimensions(Obj)
        Obj = retainKernelDimensions(Obj,keepLogical)
    end
    
    
    properties (SetAccess = protected)
        % Specifies if prtAction object has been trained.
        isTrained = false;  
    end
    
    methods
        
        function Obj3 = and(Obj1,Obj2)
            if isa(Obj1,'prtKernelSet')
                kernelCell1 = Obj1.getKernelCell;
            elseif isa(Obj1,'prtKernel2')
                kernelCell1 = {Obj1};
            else
                error('prt:prtKernel','Invalid input to prtKernel\and, both arguments must be of type prtKernel');
            end
            
            if isa(Obj2,'prtKernelSet')
                kernelCell2 = Obj2.getKernelCell;
            elseif isa(Obj2,'prtKernel2')
                kernelCell2 = {Obj2};
            else
                error('prt:prtKernel','Invalid input to prtKernel\and, both arguments must be of type prtKernel');
            end
            Obj3 = prtKernelSet(kernelCell1{:},kernelCell2{:});
        end
        
    end
end