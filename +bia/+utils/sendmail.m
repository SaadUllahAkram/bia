function sendmail()
% call this function to send an e-mail (notification) that the code is finished
% only works on linux servers with e-mail set-up

if ~exist('private_info.m', 'file')
    return
end
[mail, password, pc] = private_info();
time = datetime('now','Format','H:m - d-MMM-y');

title = 'MATLAB Auto';
message = sprintf('%s : Time: %s', pc, time);

if isunix% http://stackoverflow.com/questions/20318770/send-mail-from-linux-terminal-in-one-line    
    cmd = sprintf('echo "%s" | mail -s "%s" %s', message, title, mail);
    status = unix(cmd);
    if status ~= 0
        bia.print.fprintf('*red', 'Something went wrong, mail could not be sent')
    end
else
    fprintf('e-mail not working on windows')
%     setpref('Internet','E_mail',mail);
%     setpref('Internet','SMTP_Server','smtp.mail.com');
%     setpref('Internet','SMTP_Username',mail);
%     setpref('Internet','SMTP_Password',password);
%     props = java.lang.System.getProperties;
%     props.setProperty('mail.smtp.auth','true');
%     props.setProperty('mail.smtp.starttls.enable','true');  % Note: 'true' as a string, not a logical value!
%     props.setProperty('mail.smtp.socketFactory.port','465');
%     props.setProperty('mail.smtp.socketFactory.class','javax.net.ssl.SSLSocketFactory');
%     sendmail(mail,title,message)
end

end