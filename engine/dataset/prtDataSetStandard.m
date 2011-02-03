classdef prtDataSetStandard < prtDataSetBase
    % prtDataSetStandard  Standard Data Set Object
    %
    %   DATASET = prtDataSetStandard returns a standard data set object
    %
    %   DATASET = prtDataSetStanard(PROPERTY1, VALUE1, ...) constructs a
    %   prtDataSetStandard object DATASET with properties as specified by
    %   PROPERTY/VALUE pairs.
    %
    %   A prtDataSetStandard object inherits all properties from the
    %   prtDataSetBase class. In addition, it has the following properties:
    %
    %   observations     - A matrix of observations that has size nObservations
    %                      by nFeatures, i.e. each row contains one observation
    %                      made up of nFeatures.
    %   targets          - The class corresponding to each observation. The
    %                      number of targets must be empty, or equal the
    %                      number of observations.
    %   nObservations    - The number of observations, read-only.
    %   nFeatures        - The number of features per observation, read-only
    %   isLabeled        - Flag indicating whether the data is labeled or not,
    %                      read only.
    %   name             - String variable containing the name of the data set
    %   description      - Description of data set
    %   userData         - Additional data user may include with data set
    %
    %
    %   See also: prtDataSetBase, prtDataSetClass, prtDataSetRegress,
    
    
    properties (Dependent)
        nObservations         % The number of observations
        nFeatures             % The number of features
        nTargetDimensions     % The number of dimensions of the target data
        observationInfo       % Additional data per observation
    end
    
    properties (GetAccess = 'private',SetAccess = 'private', Hidden=true)
        observationInfoDepHelper
    end
    
    properties (SetAccess='protected',GetAccess ='protected')
        data                % The observations
        targets             % The targets
        featureNames        % The feature names
    end
    
    methods (Access = 'protected', Hidden = true)
        
        function obj = catTargetNames(obj,newDataSet)
            
            for i = 1:newDataSet.nTargetDimensions;
                currTargName = newDataSet.targetNames.get(i);
                
                if ~isempty(currTargName)
                    obj.targetNames = obj.targetNames.put(i + obj.nTargetDimensions,currTargName);
                end
            end
        end
        
        function obj = retainTargetNames(obj,varargin)
            
            retainIndices = prtDataSetBase.parseIndices(obj.nTargetDimensions,varargin{:});
            %parse returns logicals
            if islogical(retainIndices)
                retainIndices = find(retainIndices);
            end
            
            %copy the hash with new indices
            %newHash = java.util.Hashtable;
            newHash = prtUtilIntegerAssociativeArray;
            for retainInd = 1:length(retainIndices);
                if obj.targetNames.containsKey(retainIndices(retainInd));
                    newHash = newHash.put(retainInd,obj.targetNames.get(retainIndices(retainInd)));
                end
            end
            
            obj.targetNames = newHash;
        end
        
        function obj = catFeatureNames(obj,newDataSet)
            for i = 1:newDataSet.nFeatures;
                currFeatName = newDataSet.featureNames.get(i);
                if ~isempty(currFeatName)
                    obj.featureNames = obj.featureNames.put(i + obj.nFeatures,currFeatName);
                end
            end
        end
        
        function obj = retainFeatureNames(obj,varargin)
            
            retainIndices = prtDataSetBase.parseIndices(obj.nFeatures,varargin{:});
            %parse returns logicals
            if islogical(retainIndices)
                retainIndices = find(retainIndices);
            end
            
            %copy the hash with new indices
            newHash = prtUtilIntegerAssociativeArray;
            for retainInd = 1:length(retainIndices);
                if obj.featureNames.containsKey(retainIndices(retainInd));
                    newHash = newHash.put(retainInd,obj.featureNames.get(retainIndices(retainInd)));
                end
            end
            obj.featureNames = newHash;
        end
    end
    methods
        
        % Constructor
        function obj = prtDataSetStandard(varargin)
            obj.featureNames = prtUtilIntegerAssociativeArray;
            
            if nargin == 0
                return;
            end
            if isa(varargin{1},'prtDataSetStandard')
                obj = varargin{1};
                varargin = varargin(2:end);
            end
            
            if length(varargin) >= 1 && isa(varargin{1},'double')
                obj = obj.setObservations(varargin{1});
                varargin = varargin(2:end);
                
                if length(varargin) >= 1 && ~isa(varargin{1},'char')
                    if (isa(varargin{1},'double') || isa(varargin{1},'logical'))
                        obj = obj.setTargets(varargin{1});
                        varargin = varargin(2:end);
                    else
                        error('prtDataSet:InvalidTargets','Targets must be a double or logical array; but targets provided is a %s',class(varargin{1}));
                    end
                end
            end
            
            %handle public access to observations and targets, via their
            %pseudonyms.  If these were public, this would be simple... but
            %they are not public.
            dataIndex = find(strcmpi(varargin(1:2:end),'observations'));
            targetIndex = find(strcmpi(varargin(1:2:end),'targets'));
            stringIndices = 1:2:length(varargin);
            
            if ~isempty(dataIndex) && ~isempty(targetIndex)
                obj = prtDataSetStandard(varargin{stringIndices(dataIndex)+1},varargin{stringIndices(targetIndex)+1});
                newIndex = setdiff(1:length(varargin),[stringIndices(dataIndex),stringIndices(dataIndex)+1,stringIndices(targetIndex),stringIndices(targetIndex)+1]);
                varargin = varargin(newIndex);
            elseif ~isempty(dataIndex)
                obj = prtDataSetStandard(varargin{dataIndex+1});
                newIndex = setdiff(1:length(varargin),[stringIndices(dataIndex),stringIndices(dataIndex)+1]);
                varargin = varargin(newIndex);
            elseif ~isempty(targetIndex)
                obj = obj.setTargets(varargin{stringIndices(targetIndex)+1});
                newIndex = setdiff(1:length(varargin),[stringIndices(targetIndex),stringIndices(targetIndex)+1]);
                varargin = varargin(newIndex);
            end
            
            removeInd = [];
            for i = 1:2:length(varargin)
                if strcmpi(varargin{i},'featureNames')
                    obj = obj.setFeatureNames(varargin{i+1});
                    removeInd = cat(2,removeInd,i,i+1);
                    % % Not for prtDataSetStandard; prtDataSetClass Only
                    %  elseif strcmpi(varargin{i},'classNames')
                    %  obj = obj.setClassNames(varargin{i+1});
                    %  removeInd = cat(2,removeInd,i,i+1);
                elseif strcmpi(varargin{i},'observationNames')
                    obj = obj.setObservationNames(varargin{i+1});
                    removeInd = cat(2,removeInd,i,i+1);
                end
            end
            
            obj = prtUtilAssignStringValuePairs(obj,varargin{:});
        end
        
        function featNames = getFeatureNames(obj,varargin)
            % getFeatureNames  Return the prtDataSetStandard feature names
            %
            %   featNames = dataSet.getFeatureNames() Return a cell array of
            %   the dataSet object feature names. If setFeatureNames has not been
            %   called or the 'featureNames' field was not set at construction,
            %   default behavior is to return sprintf('Feature %d',i) for all
            %   features.
            %
            %   featNames = dataSet.getFeatureNames(INDICES) Return the feature
            %   names at the specified INDICES.
            
            indices2 = prtDataSetBase.parseIndices(obj.nFeatures,varargin{:});
            
            %parse returns logicals
            if islogical(indices2)
                indices2 = find(indices2);
            end
            
            featNames = cell(length(indices2),1);
            for i = 1:length(indices2)
                featNames{i} = obj.featureNames.get(indices2(i));
                if isempty(featNames{i})
                    featNames(i) = prtDataSetStandard.generateDefaultFeatureNames(indices2(i));
                end
            end
        end
        
        function obj = setFeatureNames(obj,featNames,varargin)
            % setFeatureNames  Set the prtDataSetStandard feature names
            %
            %   dataSet = dataSet.setFeatureNames(FEATNAMES) sets the
            %   feature names of the dataSet object. FEATNAMES must be a
            %   cell array of strings, and must have the same number of
            %   elements as the object has features.
            %
            %   dataSet = dataSet.setFeatureNames(FEATNAMES, INDICES) sets the
            %   feature names of the dataSet object at the corresponding
            %   INDICES.
            
            %             if isempty(featNames)
            %                 return;
            %             end
            
            if ~isa(featNames,'cell') || ~isa(featNames{1},'char')
                error('prt:dataSetStandard:setFeatureNames','Input feature names must be a cell array of characters');
            end
            if ~isvector(featNames)
                error('prt:dataSetStandard:setFeatureNames','setFeatureNames requires first input to be a n x 1 cell array');
            end
            featNames = featNames(:);
            
            indices2 = prtDataSetBase.parseIndices(obj.nFeatures,varargin{:});
            if nargin < 3
                %clear the old feature names:
                obj.featureNames = prtUtilIntegerAssociativeArray;
                if size(featNames,1) ~= length(indices2)
                    error('prt:dataSetStandard:setFeatureNames','setFeatureNames with one input requires that size(names,1) (%d) equals number of features (%d)',size(featNames,1),obj.nFeatures);
                end
            end
            if length(featNames) > obj.nFeatures
                error('prtDataSetStandard:setFeatureNames','Attempt to set feature names for more features than exist \n%d feature names provided, but object only has %d features',length(featNames),obj.nFeatures);
            end
            %parse returns logicals
            if islogical(indices2)
                indices2 = find(indices2);
            end
            
            %Put the default string names in there; otherwise we might end
            %up with empty elements in the cell array
            for i = 1:length(indices2)
                obj.featureNames = obj.featureNames.put(indices2(i),featNames{i});
            end
        end
        
        
        function [data,targets] = getObservationsAndTargets(obj,varargin)
            % getObservationsAndTargets  Get the observations and targets
            % of a prtDataSetStandard object.
            %
            %[DATA,TARGETS] = dataSet.getObservationsAndTargets() Returns
            %the observations and targets of the dataSet object.
            %
            %[DATA,TARGETS] = dataSet.getObservationsAndTargets(INDICES) Returns
            %the observations and targets of the dataSet object at the
            %specified INDICES.
            
            %[data,targets] = getObservationsAndTargets(obj,indices1,indices2,targetIndices)
            % XXX Not doc'ing for the time being
            [indices1, indices2, indices3] = prtDataSetBase.parseIndices([obj.nObservations, obj.nFeatures obj.nTargetDimensions],varargin{:});
            
            data = obj.getObservations(indices1, indices2);
            targets = obj.getTargets(indices1, indices3);
        end
        
        function obj = setObservationsAndTargets(obj,data,targets)
            % setObservationsAndTargets  Set the observations and targets
            % of a prtDataSetStandard object.
            %
            % dataSet = dataSet.setObservationsAndTargets(DATA, TARGETS)
            % sets the observations and targets to the DATA and TARGETS.
            % The number of TARGETS must be equal to the number of
            % observations contained in DATA.
            
            %disp('should this clear all the names?');
            if ~isempty(targets) && size(data,1) ~= size(targets,1)
                error('prtDataSet:invalidDataTargetSet','Data and non-empty target matrices must have the same number of rows, but data is size %s and targets are size %s',mat2str(size(data)),mat2str(size(targets)));
            end
            obj.data = data;
            obj.targets = targets;
            
            % Updated chached data info
            obj = updateObservationsCache(obj);
            
            % Reset the target cache
            obj = updateTargetsCache(obj);
        end
        
        function data = getObservations(obj,varargin)
            % getObservations  Get the observations of a prtDataSetStandard
            % object.
            %
            %DATA = dataSet.getObservations() Returns
            %the observations of the dataSet object.
            %
            %DATA = dataSet.getObservations(INDICES) Returns
            %the observations of the dataSet object at the specified INDICES.
            
            %Modified 8/21/2010 - assume the indices are all valid, and
            %try/catch them.  If they're not valid, use
            %prtDataSetBase.parseIndices to error gracefully.
            try
                switch nargin
                    case 1
                        % No indicies identified. Quick exit
                        data = obj.data;
                    case 2
                        data = obj.data(varargin{1},:);
                    case 3
                        data = obj.data(varargin{1},varargin{2});
                    otherwise
                        error('prt:prtDataSetStandard:getObservations','getObservations expects 1 or 2 sets of indices; %d indices provided',nargin-1);
                end
            catch ME
                %this should error with a meaningful message:
                prtDataSetBase.parseIndices([obj.nObservations, obj.nFeatures],varargin{:});
                %Otherwise, something else happened; show the user
                throw(ME);
            end
        end
        
        function obj = setObservations(obj, data, varargin)
            % SetObservations  Set the observations prtDataSetStandard
            % object.
            %
            % dataSet = dataSet.setObservations(DATA) sets the observations
            % to DATA.
            %
            % dataSet = dataSet.setObservations(DATA, INDICES), sets the
            % observations to DATA at the specified INDICES
            
            %obj = setObservations(obj,data,indices1,indices2)
            % XXX Leaving un-doc'd for now
            
            %Modified 8/21/2010 - assume the indices are all valid, and
            %try/catch them.  If they're not valid, use
            %prtDataSetBase.parseIndices to error gracefully.
            if nargin < 3
                % Setting the entire data matrix
                if obj.isLabeled && obj.nObservations ~= size(data,1)
                    error('prtDataSet:invalidDataTargetSet','Attempt to change size of observations in a labeled data set; use setObservationsAndTargets to change both simultaneously');
                end
                obj.data = data;
            else
                try
                    switch nargin
                        case 3
                            obj.data(varargin{1},:) = data;
                        case 4
                            obj.data(varargin{1},varargin{2}) = data;
                        otherwise
                            error('prt:prtDataSetStandard:setObservations','setObservations expects 1 or 2 sets of indices; %d indices provided',nargin-2);
                    end
                catch ME
                    %this should error with a meaningful message:
                    prtDataSetBase.parseIndices([obj.nObservations, obj.nFeatures],varargin{:});
                    %Otherwise, something else happened; show the user
                    throw(ME);
                end
            end
            % Reset the data cache
            obj = updateObservationsCache(obj);
            
            % Note: fix this!
            %obj = obj.fixObservationFeatureNames;
        end
        
        function targets = getTargets(obj,varargin)
            % getTargets  Get the targets of a prtDataSetStandard object.
            %
            %TARGETS = dataSet.getTargets() Returns the targets of the
            %dataSet object.
            %
            %TARGETS = dataSet.getTargets(INDICES) Returns the targets of
            %the dataSet object at the specified INDICES.
            
            %[data,targets] = getTargets(obj,indices1,indices2)
            % XXX Leaving un-doc'd for now
            
            
            if nargin == 1
                % No indicies identified. Quick exit
                targets = obj.targets;
                return
            end
            
            if obj.isLabeled
                try
                    switch nargin
                        case 2
                            targets = obj.targets(varargin{1},:);
                        case 3
                            targets = obj.targets(varargin{1},varargin{2});
                        otherwise
                            error('prt:prtDataSetStandard:getTargets','getTargets expects 1 or 2 sets of indices; %d indices provided',nargin-1);
                    end
                catch ME
                    %this should error with a meaningful message:
                    prtDataSetBase.parseIndices([obj.nObservations, obj.nTargetDimensions],varargin{:});
                    %Otherwise, something else happened; show the user
                    throw(ME);
                end
            else
                targets = [];
            end
        end
        
        function obj = setTargets(obj,targets,varargin)
            % setTargets  Set the Targets prtDataSetStandard object.
            %
            % dataSet = dataSet.setTargets(TARGETS) sets the targets
            % to DATA.
            %
            % dataSet = dataSet.setTargets(TARGETS, INDICES), sets the
            % targets to TARGETS at the specified INDICES
            
            %obj = setTargets(obj,targets,indices1,indices2)
            % XXX leaving un-doc'd for now
            
            
            % Setting only specified entries of the matrix
            [indices1, indices2] = prtDataSetBase.parseIndices([obj.nObservations, obj.nTargetDimensions],varargin{:});
            
            %Handle empty targets (2-D)
            if isempty(indices2)
                indices2 = 1:size(targets,2);
            end
            %Handle empty targets (1-D)
            if isempty(indices1) && ~isempty(targets);
                indices1 = 1:obj.nObservations;
            end
            
            if ~isempty(targets)
                if nargin < 3
                    if ~isequal(obj.nObservations,size(targets,1))
                        error('prt:prtDataSetStandard:InvalidTargetSize','nObservations is %d, but targets are of size %s, corresponding to %d observations',obj.nObservations,mat2str(size(targets)),size(targets,1));
                    end
                end
                if ~isequal([length(indices1),length(indices2)],size(targets))
                    if isempty(obj.targets) && nargin < 3
                        error('prtDataSetStandard:InvalidTargetSize','Attempt to set targets to matrix of size %s, but indices are of size [%d %d]',mat2str(size(targets)),length(indices1),length(indices2))
                    else
                        error('prtDataSetStandard:InvalidTargetSize','Attempt to set targets to matrix of size %s, but targets is size %s',mat2str(size(targets)),mat2str(size(obj.targets)));
                    end
                end
                
                obj.targets(indices1,indices2) = targets;
            else
                obj.targets = [];
            end
            
            % Updated chached target info
            obj = updateTargetsCache(obj);
        end
        
        function obj = catObservations(obj, varargin)
            %catObservations  Concatenate to the observations of a
            %prtDataSetStandard object
            %
            % dataSet = dataSet.catObservation(OBSERVATIONS) concatenates
            % OBSERVATIONS the observations of a prtDataSetStandard object.
            % OBSERVATIONS must have the same number of features as the
            % dataSet object.
            
            if nargin == 1
                return;
            end
            
            for argin = 1:length(varargin)
                currInput = varargin{argin};
                if isa(currInput,class(obj.data))
                    if isempty(obj.targets)
                        obj.data = cat(1,obj.data, currInput);
                    else
                        error('prt:prtDataSetStandard:CatObservations','Attempt to cat observations using a double matrix to a prtDataSetStandard that has targets; this will result in target/observation mis-match');
                    end
                elseif isa(currInput,class(obj))
                    
                    if isempty(obj.data) %handle empty data set
                        obj.data = currInput.data;
                        obj.targets = currInput.targets;
                    elseif (isempty(obj.targets) && isempty(currInput.targets)) || (~isempty(obj.targets) && ~isempty(currInput.targets))
                        obj.data = cat(1,obj.data,currInput.getObservations);
                        obj.targets = cat(1,obj.targets,currInput.getTargets);
                    else
                        error('prt:prtDataSetStandard:CatObservations','Attempt to cat observations for data sets with different sized targets');
                    end
                    obj = obj.catObservationNames(currInput);
                    obj = obj.catObservationInfo(currInput);
                end
            end
            
            % Updated chached target info
            obj = updateTargetsCache(obj);
            
            % Updated chached data info
            obj = updateObservationsCache(obj);
        end
        
        function [obj,retainedIndices] = removeObservations(obj,removeIndices)
            % removeObservations  Remove observations from a prtDataSetStandard object
            %
            % dataSet = dataSet.removeObservations(INDICES) removes the
            % observations at the specified INDICES
            
            removeIndices = prtDataSetBase.parseIndices(obj.nObservations ,removeIndices);
            
            if islogical(removeIndices)
                keepObservations = ~removeIndices;
            else
                keepObservations = setdiff(1:obj.nObservations,removeIndices);
            end
            
            [obj,retainedIndices] = retainObservations(obj,keepObservations);
        end
        
        function [obj,retainedIndices] = retainObservations(obj,retainedIndices)
            % retainObservations   Retain observations from a prtDataSetStandard object
            %
            % dataSet = dataSet.retainObservations(INDICES) removes all
            % observations from the dataSet object except those specified
            % by INDICES
            
            try
                obj = obj.retainObservationNames(retainedIndices);
                obj.data = obj.data(retainedIndices,:);
                if obj.isLabeled
                    obj.targets = obj.targets(retainedIndices,:);
                end
                
                if ~isempty(obj.observationInfo)
                    obj.observationInfo = obj.observationInfo(retainedIndices);
                end
                
                % Updated chached target info
                obj = updateTargetsCache(obj);

                % Updated chached data info
                obj = updateObservationsCache(obj);
            catch  %#ok<CTCH>
                retainedIndices = prtDataSetBase.parseIndices(obj.nObservations ,retainedIndices);
            end
            
        end
        
        function [obj,retainedFeatures] = removeFeatures(obj,removeIndices)
            % retainFeatures   Retain the features of a prtDataSetStandard object.
            %
            % dataSet = dataSet.retainFeatures(INDICES) removes all
            % features from the dataSet object except those specified by
            % INDICES
            
            removeIndices = prtDataSetBase.parseIndices(obj.nFeatures ,removeIndices);
            if islogical(removeIndices)
                keepFeatures = ~removeIndices;
            else
                keepFeatures = setdiff(1:obj.nFeatures,removeIndices);
            end
            [obj,retainedFeatures] = retainFeatures(obj,keepFeatures);
        end
        
        function [obj,retainedFeatures] = retainFeatures(obj,retainedFeatures)
            % retainFeatures   Retain the features of a prtDataSetStandard
            % object
            %
            % dataSet = dataSet.retainFeatures(INDICES) removes all
            % features from the dataSet object except those specified by
            % INDICES
            
            retainedFeatures = prtDataSetBase.parseIndices(obj.nFeatures ,retainedFeatures);
            obj = obj.retainFeatureNames(retainedFeatures);
            obj.data = obj.data(:,retainedFeatures);
            
            % Updated chached data info
            obj = updateObservationsCache(obj);
        end
        
        function data = getFeatures(obj,varargin)
            % getFeatures   Return the features of a prtDataSetStandard
            % object
            %
            % FEATURES = dataSet.getFeatures() returns the features of the
            % dataSet object
            %
            % FEATURES = dataSet.getFeatures(INDICES) returns only the
            % features of the dataSet object specified by INDICES
            
            featureIndices = prtDataSetBase.parseIndices(obj.nFeatures ,varargin{:});
            data = obj.getObservations(:,featureIndices);
        end
        
        function obj = setFeatures(obj,data,varargin)
            % setFeatures   Set the features of a prtDataSetStandard object
            %
            % dataSet = dataSet.setFeatures(FEATURES) set the features of
            % the dataSet object to FEATURES
            %
            % dataSet = dataSet.setFeatures(FEATURES, INDICES) set the features of
            % the dataSet object to FEATURES at the specified INDICES
            
            obj = obj.setObservations(data,:,varargin{:});
        end
        
        function obj = catFeatures(obj, varargin)
            % catFeatures   Concatenate the features of a prtDataSetStandard object
            %
            % dataSet = dataSet.catFeatures(FEATURES) concatenates the
            % FEATURES to the features of the dataSet object. FEATURES must
            % have the same number of observations as the dataSet object.
            
            if nargin == 1
                return;
            end
            for argin = 1:length(varargin)
                currInput = varargin{argin};
                if isa(currInput,class(obj.data))
                    obj.data = cat(2,obj.data, currInput);
                elseif isa(currInput,class(obj))
                    obj = obj.catFeatureNames(currInput);
                    obj.data = cat(2,obj.data,currInput.getObservations);
                end
            end
            % Updated chached data info
            obj = updateObservationsCache(obj);
        end
        
        function [obj, sampleIndices] = bootstrap(obj,nSamples,p)
            % bootstrap  boostrap a prtDataSetStandard object
            %
            % dataSet = dataSet.boostrap(NSAMPLES) returns a dataSet object
            % consisting of NSAMPLES randomly selected samples from the
            % original dataSet object.
            
            if nargin < 3
                p = ones(obj.nObservations,1)./obj.nObservations;
            end
            assert(isvector(p) & all(p) <= 1 & all(p) >= 0 & prtUtilApproxEqual(sum(p),1,eps(obj.nObservations)) & length(p) == obj.nObservations,'prt:prtDataSetStandard:bootstrap','invalid input probability distribution; distribution must be a vector of size obj.nObservations x 1, and must sum to 1')
            
            if obj.nObservations == 0
                error('prtDataSetStandard:BootstrapEmpty','Cannot bootstrap empty data set');
            end
            if nargin < 2 || isempty(nSamples)
                nSamples = obj.nObservations;
            end
            
            % We could do this
            % >>rv = prtRvMultinomial('probabilities',p(:));
            % >>sampleIndices = rv.drawIntegers(nSamples);
            % but there is overhead associated with RV object creation.
            % For some actions, TreebaggingCap for example, we need to
            % rapidly bootstrap so we do not use the object
            sampleIndices = prtRvUtilRandomSample(p,nSamples);
            
            obj = obj.retainObservations(sampleIndices);
        end
        
        function nObservations = get.nObservations(obj)
            % nObservations  Return the number of observations from a
            % prtDataSetStandard object
            %
            % nObjervations = dataSet.nObservations() returns the number of
            % observations from the dataSet object.
            nObservations = obj.determineNumObservations;
        end
        
        function nObservations = determineNumObservations(obj)
            nObservations = size(obj.data,1);
        end
        
        function nFeatures = get.nFeatures(obj)
            % nFeatures  Return the number of features from a
            % prtDataSetStandard object
            %
            % nObjervations = dataSet.nObservations() returns the number of
            % observations from the dataSet object.
            nFeatures = determineNumFeatures(obj);
        end
        
        function nFeatures = determineNumFeatures(obj)
            % nFeatures  Return the number of features from a
            % prtDataSetStandard object
            %
            % nObjervations = dataSet.nObservations() returns the number of
            % observations from the dataSet object.
            nFeatures = size(obj.data,2);
        end
        
        function nTargetDimensions = get.nTargetDimensions(obj)
            %nTargetDimensions = get.nTargetDimensions(obj)
            nTargetDimensions = size(obj.targets,2); %use InMem's .data field
        end
        

        function obj = setObservationInfoEntry(obj,inds,fieldName,val)
            % setObservationInfoEntry - set observationInfo for specified
            % observations
            %
            % ds = prtDataGenUnimodal;
            % obsInfoPart.field1 = 0.2;
            % ds = ds.setObservationInfoEntry(1,obsInfoPart);
            % ds = ds.setObservationInfoEntry(1,'field1',obsInfoPart.field1)
            
            assert(nargin >= 3, 'prt:prtDataSetStandard:setObservationInfoEntry','invalid number of inputs');
            
            if ~isstruct(fieldName)
                if nargin > 3
                    obsInfoPart.(fieldName) = val;
                else
                    error('prt:prtDataSetStandard:setObservationInfoEntry','setObservationInfoEntry with two aditional inputs requires that the second is a structure');
                end
            else
                obsInfoPart = fieldName;
            end
            
            newFieldNames = fieldnames(obsInfoPart);
            
            structInputs = cell(length(newFieldNames)*2,1);
            structInputs(1:2:end) = newFieldNames;
            newObsInfo = repmat(struct(structInputs{:}),obj.nObservations,1);
            try
                newObsInfo(inds) = obsInfoPart;
            catch ME
                % Bad indexes supplied
                keyboard
            end
            
            % Quick exit if we didn't have anything
            if isempty(obj.observationInfo)
                obj.observationInfo = newObsInfo;
                return
            end
            
            cObsInfo = obj.observationInfo;
            
            keyboard
            
            % newObsInfo = prtUtilMergeStructures(newObsInfo,cObsInfo);
            
            
        end
            
        function obj = set.observationInfo(obj,Struct)
            % Error checks for setting observationInfo in batch mode
            
            if isempty(Struct)
                % Empty is ok.
                % It has to be for loading and saving.
                return
            end
            
            errorMsg = 'observationInfo must be an nObservations x 1 structure array. It cannot be set through indexing.';
            assert(isa(Struct,'struct'),errorMsg);
            
            if numel(Struct) == 1
                % We are probably trying to set an individual enetry of
                % observation info. Provide a nice message explaining to
                % use setObservationInfoEntry
                error('prt:prtDataSetStandard:observationInfo','The observationInfo for a single observation cannot be set in this manner. Instead use setObservationInfoEntry().')
            else
                assert(numel(Struct)==obj.nObservations,errorMsg);
            end
            
            obj.observationInfoDepHelper = Struct(:);
        end
        function val = get.observationInfo(obj)
            val = obj.observationInfoDepHelper;
        end
        
        
        function obj = select(obj, selectFunction)
            % Select observations to retain by specifying a function
            %   The specified function is evaluated on each obesrvation.
            % 
            % selectedDs = ds.select(selectFunction);
            % 
            % There are two ways to define selectionFunction
            %   One input, One logical vector output
            %       selectFunction recieves the input data set and must
            %       output a nObservations by 1 logical vector.
            %   One input, One logical scalar output
            %       selectFunction recieves the ObservatioinInfo structure
            %       of a single observation.
            %
            % Examples:
            %   ds = prtDataGenIris;
            %   ds = ds.setobservationInfo('asdf',randn(ds.nObservations,1));
            %   
            %   dsSmallobservationInfoSelect = ds.select(@(ObsInfo)ObsInfo.asdf > 0.5);
            %   
            %   dsSmallObservationSelect = ds.select(@(inputDs)inputDs.getObservations(:,1)>6);

            assert(isa(selectFunction, 'function_handle'),'selectFunction must be a function handle.');
            assert(nargin(selectFunction)==1,'selectFunction must be a function handle that take a single input.');
                
            try
                keep = selectFunction(obj);
                assert(size(keep,1)==obj.nObservations);
                assert(islogical(keep) || (isnumeric(keep) && all(ismember(keep,[0 1]))));
            catch %#ok<CTCH>
                if isempty(obj.observationInfo)
                    error('prt:prtDataSetStandard:select','selectFunction did not return a logical vector with nObservation elements and this data set object does not contain observationInfo. Therefore this selecFunction is not valid.')
                end
                
                keep = false(obj.nObservations,1);
                for iObs = 1:obj.nObservations
                    try
                        cOut = selectFunction(obj.observationInfo(iObs));
                    catch %#ok<CTCH>
                        error('prt:prtDataSetStandard:select','selectFunction did not return a logical vector with nObservation elements and there was an evaluation error using this function. See help prtDataSetStandard/select');
                    end
                    assert(numel(cOut)==1,'selectFunction did not return a logical vector with nObservation elements but also did not return scalar logical.');
                    assert((islogical(cOut) || (isnumeric(cOut) && (cOut==0 || cOut==1))),'selectFunction that returns one output must output a 1x1 logical.');
                    
                    keep(iObs) = cOut;
                end
            end
            obj = obj.retainObservations(keep);
        end
        
        function val = getObservationInfo(obj,fieldName)
            % Allow for fast retrieval of observation info by specifying
            % the field name(fieldName)
            % 
            % DS = prtDataGenIris;
            % DS = DS.setObservationInfo('asdf',randn(DS.nObservations,1),'qwer',randn(DS.nObservations,1),'poiu',randn(DS.nObservations,10),'lkjh',mat2cell(randn(DS.nObservations,1),ones(DS.nObservations,1),1),'mnbv',mat2cell(randn(DS.nObservations,10),ones(DS.nObservations,1),10));
            % vals = DS.getObservationInfo('asdf');
            
            assert(isfield(obj.observationInfo,fieldName),'prt:prtDataSetStandard:getObservationInfo','%s is not a field name of observationInfo for this dataset');
            try
                val = cat(1,obj.observationInfo.(fieldName));
            catch % This failed because of invalid matrix dimensions
                try
                    val = {obj.observationInfo.(fieldName)}';
                catch 
                    error('prt:prtDataSetStandard:getObservationInfo','getObservationInfo failed to trieve the necessary field for an unknown reason');
                end
            end
            
        end
        
        function obj = setObservationInfo(obj,varargin)
            % Allow setting of observation info by specifying string value
            % pairs
            % 
            % DS = prtDataGenIris;
            % DS = DS.setObservationInfo('asdf',randn(DS.nObservations,1),'qwer',randn(DS.nObservations,1),'poiu',randn(DS.nObservations,10),'lkjh',mat2cell(randn(DS.nObservations,1),ones(DS.nObservations,1),1),'mnbv',mat2cell(randn(DS.nObservations,10),ones(DS.nObservations,1),10));
            
            nIn = length(varargin);
            if nIn == 1
                % should be a struct. if it isn't will just
                % let set.observationInfo() spit the error
                obj.observationInfo = varargin{1};
                return
            end
            
            errorMsg = 'If more than one input is specified, the inputs must be string value pairs.';
            assert(mod(length(varargin),2)==0, errorMsg)
            paramNames = varargin(1:2:end);
            params = varargin(2:2:end);
            
            assert(iscellstr(paramNames), errorMsg)
            
            cStruct = obj.observationInfo;
            if isempty(cStruct)
                startingFieldNames = {};
            else
                startingFieldNames = fieldnames(cStruct);
            end
            
            for iParam = 1:length(paramNames)
                
                cVal = params{iParam};
                cName = paramNames{iParam};
                assert(isvarname(cName),'observationInfo fields must be valid MATLAB variable names. %s is not.',cName);
                
                if ismember(cName,startingFieldNames)
                    warning('prt:observationInfoNameCollision','An observationInfo field named %s already exists. The data is now overwritten.', cName)
                end
                assert(size(cVal,1) == obj.nObservations,'observationInfo values must have nObservations rows.');
                
                cValSet = mat2cell(cVal,ones(size(cVal,1),1),size(cVal,2));
                
                if isempty(cStruct)
                    cStruct = struct(cName,cValSet);
                else
                    for iObs = 1:obj.nObservations
                        cStruct(iObs).(cName) = cValSet{iObs,:};
                    end
                end
            end
            
            obj.observationInfo = cStruct;
        end
        
        function obj = catObservationInfo(obj, newDataSet)
            
            if isempty(newDataSet.observationInfo) && isempty(obj.observationInfo)
                return;
            end
            
            if ~isequal(fieldnames(obj.observationInfo),fieldnames(newDataSet.observationInfo))
                error('prt:prtDataSetStandard:catObservationInfo','observationInfo structures for these datasets do not match.');
            end
            
            obj.observationInfo = cat(1,obj.observationInfo,newDataSet.observationInfo);
        end
        
        
        function obj = catTargets(obj, varargin)
            % catTargets  Concatenate the targets of a prtDataSetStandard
            % object
            %
            % dataSet = dataSet.catTargets(TARGETS) concatenates the
            % targets with TARGETS. TARGETS must have the same number of
            % observations as dataSet.
            
            if nargin == 1
                return;
            end
            for argin = 1:length(varargin)
                currInput = varargin{argin};
                if isa(currInput,class(obj.targets))
                    obj.targets = cat(2,obj.targets, currInput);
                elseif isa(currInput,'prtDataSetStandard')
                    obj = obj.catTargetNames(currInput);
                    obj.targets = cat(2,obj.targets,currInput.getTargets);
                end
            end
            % Updated chached target info
            obj = updateTargetsCache(obj);
        end
        
        function [obj,retainedTargets] = removeTargets(obj,removeIndices)
            % removeTargets  Remove targets from a prtDataSetStandard
            % object.
            %
            % dataSet = dataSet.retainTargets(INDICES) removes the targets
            % from the dataSet object specified by INDICES
            
            warning('prt:Fixable','Does not handle feature names');
            
            removeIndices = prtDataSetBase.parseIndices(obj.nTargetDimensions,removeIndices);
            
            if islogical(removeIndices)
                keepFeatures = ~removeIndices;
            else
                keepFeatures = setdiff(1:obj.nFeatures,removeIndices);
            end
            [obj,retainedTargets] = retainTargets(obj,keepFeatures);
        end
        
        function [obj,retainedTargets] = retainTargets(obj,retainedTargets)
            % retainTargets  Retain targets from a prtDataSetStandard
            % object.
            %
            % dataSet = dataSet.retainTargets(INDICES) removes all targets
            % from the dataSet object except those specified by INDICES
            
            retainedTargets = prtDataSetBase.parseIndices(obj.nTargetDimensions ,retainedTargets);
            obj = obj.retainTargetNames(retainedTargets);
            obj.targets = obj.targets(:,retainedTargets);
            
            % Updated chached target info
            obj = updateTargetsCache(obj);
        end
    end
    
    methods (Hidden=true, Access='protected')
        function obj = updateTargetsCache(obj)
            % By default do nothing
            % This is can be overloaded in sub-classes
            % For example. this is overloaded in prtDataSetClass to cache
            % unique(targets) amounst other things
        end
        function obj = updateObservationsCache(obj)
            % By default do nothing
            % This is can be overloaded in sub-classes
        end
    end
    
    methods (Hidden = true)
        
        function obj = copyDescriptionFieldsFrom(obj,dataSet)
            %obj = copyDescriptionFieldsFrom(obj,dataSet)
            
            %No; do not copy featureNames; featureNames must be set by
            %Actions; the outputs of a Action are not guaranteed to have
            %the same number of features!
            
            obj.observationInfo = dataSet.observationInfo;
            obj = copyDescriptionFieldsFrom@prtDataSetBase(obj,dataSet);
        end
        
        function has = hasFeatureNames(obj)
            has = ~isempty(obj.featureNames);
        end
        
        function v = export(obj,varargin) %#ok<STOUT,MANU>
            error('prt:Fixable','prtDataSetStandard does not implement an export() function; did you mean to use a prtDataSetClass or prtDataSetRegress?');
        end
        
        function h = plot(obj,varargin) %#ok<STOUT,MANU>
            error('prt:prtDataSetStandard:plot','prtDataSetStandard does not implement a plot() function; did you mean to use a prtDataSetClass or prtDataSetRegress?');
        end
        function s = summarize(obj,varargin) %#ok<STOUT,MANU>
            error('prt:prtDataSetStandard:summarize','prtDataSetStandard does not implement a summarize() function; did you mean to use a prtDataSetClass or prtDataSetRegress?');
        end
    end
    
end