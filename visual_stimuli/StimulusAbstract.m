classdef (Abstract) StimulusAbstract < handle
    %% StimulusAbstract()
    %       this defines an abstract class which all visual stimuli will be
    %       subclasses of. it specifies that there must be a "controller" 
    %       property, and "prepare", "to_save", and "run" methods, which
    %       will be used to run the visual stimulus.
    %       controller:     contains the VisualStimulusController.m
    %                       instance
    %       prepare():      any preparation the stimulus must do (e.g.
    %                       randomization), called when starting the
    %                       controller
    %       to_save():      method which prepares a list of variables to
    %                       save. method should return a single structure
    %                       which contains the variables to save
    %       run():          this is the code that the controller will run
    
    
    properties (Abstract = true, Hidden = true, SetAccess = private)
        
        controller
    end
    
    
    
    methods (Abstract = true)
            
        prepare(obj)
        to_save(obj)
        run(obj)
    end
end


