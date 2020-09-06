function [OutputData] = OFDM_ConvolutionalCoder(InputData, CodeRate, sign)
% column vector; true or false
% column vector;

global CONV_TRELLIS CODE_RATE
global DEBUG
% GlobalVariables;
TRACEBACK = 4;     % the trace back is a parameter of the convolutional decoder

if sign == true
    
    switch CodeRate % OutputData is bit stolen data
        case 2 % CodeRate = 1/2
            handle_Conv = comm.ConvolutionalEncoder('TrellisStructure',  CONV_TRELLIS);
            OutputData = step(handle_Conv, InputData); % MiddleData is convolutional bits
            
        case 3 % CodeRate = 2/3; Punctured Coding
            handle_Conv = comm.ConvolutionalEncoder('TrellisStructure',  CONV_TRELLIS, 'PuncturePatternSource', 'Property', 'PuncturePattern', [1; 1; 1; 0]);
            OutputData = step(handle_Conv, InputData); % MiddleData is convolutional bits
            
        case 4  % CodeRate = 3/4; Punctured Coding
            handle_Conv = comm.ConvolutionalEncoder('TrellisStructure',  CONV_TRELLIS, 'PuncturePatternSource', 'Property', 'PuncturePattern', [1; 1; 1; 0; 0; 1]);
            OutputData = step(handle_Conv, InputData); % MiddleData is convolutional bits
            
        otherwise
            error('ERROR: CodeRate must be 2/3/4');
    end
    
    if DEBUG
        disp(['Convolutional encoder input: ' num2str(length(InputData)) '; Convolutional encoder output: ' num2str(length(OutputData)) '; CodeRate: ' num2str(length(InputData) / length(OutputData))])
    end

else % if sign == false
    
    switch CodeRate     % MiddleData includes inserted dummy bits
        case 2 % CodeRate = 1/2
            OutputData = [InputData; zeros(TRACEBACK * CodeRate, 1)]; % OutputData is deconvolutional bits
            handle_viterbi = comm.ViterbiDecoder('TrellisStructure', CONV_TRELLIS, 'TracebackDepth', TRACEBACK, 'InputFormat', 'Hard');
            OutputData = step(handle_viterbi, OutputData);
            OutputData = OutputData(TRACEBACK + 1: end);
            
        case 3 % CodeRate = 2/3; Punctured Coding
            OutputData = [InputData; zeros(TRACEBACK * CodeRate, 1)]; % OutputData is deconvolutional bits
            handle_viterbi = comm.ViterbiDecoder('TrellisStructure', CONV_TRELLIS, 'TracebackDepth', TRACEBACK, 'InputFormat', 'Hard', 'PuncturePatternSource', 'Property', 'PuncturePattern', [1; 1; 1; 0]);
            OutputData = step(handle_viterbi, OutputData);
            OutputData = OutputData(TRACEBACK + 1: end - TRACEBACK);
            
        case 4  % CodeRate = 3/4; Punctured Coding
            OutputData = [InputData; zeros(TRACEBACK * CodeRate, 1)]; % OutputData is deconvolutional bits
            handle_viterbi = comm.ViterbiDecoder('TrellisStructure', CONV_TRELLIS, 'TracebackDepth', TRACEBACK, 'InputFormat', 'Hard', 'PuncturePatternSource', 'Property', 'PuncturePattern', [1; 1; 1; 0; 0; 1]);
            OutputData = step(handle_viterbi, OutputData);
            OutputData = OutputData(TRACEBACK + 1: end - TRACEBACK * 2);
            
        otherwise
            error('ERROR: CodeRate must be 2/3/4');
    end
    
    if DEBUG
        disp(['Convolutional deocder input: ' num2str(length(InputData)) '; Convolutional deocder output: ' num2str(length(OutputData)) '; CodeRate: ' num2str(length(OutputData) / length(InputData))])
    end

end % end sign
