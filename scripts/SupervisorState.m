classdef SupervisorState < Simulink.IntEnumType
    % SupervisorState Enumeration for Operating Mode Supervisor
    % Top-level states: IDLE, READY, RUN, FAULT, CALIBRATION
    
    enumeration
        IDLE(0)
        READY(1)
        RUN(2)
        FAULT(3)
        CALIBRATION(4)
    end
    
    methods (Static)
        function retVal = getDefaultValue()
            retVal = SupervisorState.IDLE;
        end
        
        function retVal = getDescription()
            retVal = 'Operating mode supervisor top-level state';
        end
        
        function retVal = getDataScope()
            retVal = 'Exported';
        end
        
        function retVal = getHeaderFile()
            retVal = 'algorithm_types.h';
        end
        
        function retVal = addClassNameToEnumNames()
            retVal = false;
        end
    end
end
