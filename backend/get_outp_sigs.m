% *************************************************************************
%
%    ZZZZZZZZZZ   FFFFFFFFFF
%    ZZZZZZZZZZ   FFFFFFFFFF
%          ZZZ    FFF
%         ZZZ     FFF
%        ZZZ      FFFFFFFF
%       ZZZ       FFFFFFFF
%      ZZZ        FFF
%     ZZZ         FFF
%    ZZZZZZZZZZ   FFF
%    ZZZZZZZZZZ   FFF          FRIEDRICHSHAFEN AG
%
% *************************************************************************
%
%  Created  on  :  26-03-2020
%  Author       :  Guddeti Jagadeesh Reddy
%  Department   :  IDSIA
%  File         :  get_outp_sigs.m
%
%  Description  :  
%
% *************************************************************************
function get_outp_sigs(Frame_name,path,mat_file_name, execution_type)
    
    list_actl_out = regexprep(get_param(find_system(strtok(Frame_name,'.'),'SearchDepth',2,'BlockType','ToWorkspace'),'VariableName'),'^mo',''); %%the below command get the information of all the ToWorspace blocks present in the frame.
    sz_actl_out = size(list_actl_out); % get the size nunmber of TO worspace blocks
    [~,mat_file_name]=fileparts(mat_file_name);
    % mil_output_mat_file_name = [mat_file_name,'_mil'];
    mil_output_mat_file_name = [mat_file_name,execution_type];
    
for k = 1: sz_actl_out(1)
    %fill the name and output data in the below array.
    temp_val = evalin('base', ['mo',list_actl_out{k}]);
    str_temp = '[';
    for j = 1:length(temp_val.Data)% creatign he value string 
        if length(temp_val.Data) == 1
            str_temp = [str_temp,num2str(temp_val.Data(j)),']'];
        elseif(j == 1)
            str_temp = [str_temp,num2str(temp_val.Data(j))];
        elseif( j == length(temp_val.Data))
            str_temp = [str_temp,';',num2str(temp_val.Data(j)),']'];   
        else
            str_temp = [str_temp,';',num2str(temp_val.Data(j))];
        end
    end
    eval([mil_output_mat_file_name,'.',[list_actl_out{k},execution_type],'=',str_temp]);
    %eval([mil_output_mat_file_name,'.',[list_actl_out{k},'_MIL'],'=',str_temp]);% creating the structure of the name and value
end
get_time_data = evalin('base','t');
str_temp = '[';
   for j = 1: length(get_time_data)% creatign he value string 
        if length(temp_val.Data) == 1
            str_temp = [str_temp,num2str(temp_val.Data(j)),']'];
        elseif(j == 1)
            str_temp = [str_temp,num2str(get_time_data(j))];
        elseif( j == length(get_time_data))
            str_temp = [str_temp,';',num2str(get_time_data(j)),']'];   
        else
            str_temp = [str_temp,';',num2str(get_time_data(j))];
        end
    end
  eval([mil_output_mat_file_name,'.','t','=',str_temp]);
mat_file_full_name = [mil_output_mat_file_name,'.mat'];% appending the .mat to the name of
save(mat_file_full_name ,'-struct',mil_output_mat_file_name);% saving the values to mat file.
try
movefile(mat_file_full_name,path);% moving the mat file to the path of the test case.
catch
    movefile(mat_file_full_name,path, 'f');
end

end