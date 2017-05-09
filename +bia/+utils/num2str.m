function str = num2str(d)
% converts a number into string and displays all significant digits
%
% Input:
%     d : a number
% Output:
%     str : a string
% 
    if rem(d, 1) == 0
        str = sprintf('%d', d);
    else
        n=0;
        while (floor(d*10^n)~=d*10^n)
            n=n+1;
        end
        str = sprintf(['%.', num2str(n), 'f'], d);
    end
end
