classdef StimulusTCPIP < handle
    
    properties
        
        remote_ip             = '127.0.0.1';
        remote_port
        local_port
        order               = 'server_client';
        
        wait_signal         = 'Ready';    
    end
    
    properties (SetAccess = private)
        
        server;
        client;
    end
    
    
    
    methods
        
        function obj = StimulusTCPIP(local_port, remote_port)
            
            obj.local_port = local_port;
            obj.remote_port = remote_port;
        end
        
        
        
        function open_connection(obj)
            
            if strcmp(obj.order, 'server_client')
                obj.open_server();
                obj.open_client();
            elseif strcmp(obj.order, 'client_server')
                obj.open_client();
                obj.open_server();
            end
                
        end
        
        
        
        function open_server(obj)
            
            if obj.is_server_up()
                return
            end
            
            obj.server = tcpip(obj.remote_ip, obj.remote_port, 'NetworkRole', 'Server');
            
            fprintf('Waiting for the client at %s:%i to connect...', obj.remote_ip, obj.remote_port);
            fopen(obj.server);
            fprintf('connected.\n')
        end
        
        
        
        function open_client(obj)
            
            if obj.is_client_up()
                return
            end
            
            obj.client = tcpip(obj.remote_ip, obj.local_port, 'NetworkRole', 'Client');
            
            fprintf('Connecting as client to %s:%i...', obj.remote_ip, obj.local_port)
            fopen(obj.client);
            fprintf('connected\n')
        end
        
        
        
        function exit = is_server_up(obj)
            
            exit = true;
            
            if ~isa(obj.server, 'tcpip')
                exit = false; return
            end
            
            if strcmp(obj.server.Status, 'closed')
                exit = false; return
            end
        end
        
        
        
        function exit = is_client_up(obj)
            
            exit = true;
            
            if ~isa(obj.client, 'tcpip')
                exit = false; return
            end
            
            if strcmp(obj.client.Status, 'closed')
                exit = false; return
            end
        end
        
        
        
        function close_connection(obj)
            
            obj.close_server()
            obj.close_client()
            
            if strcmp(obj.client.Status, 'closed')
                return
            end
            
            fclose(obj.client);
        end
        
        
        function close_server(obj)
            
            if obj.is_server_up()
                fclose(obj.server);
            end
        end
        
        
        
        function close_client(obj)
            
            if obj.is_client_up()
                fclose(obj.client);
            end
        end
        
        
        
        function status = wait_for_ready(obj)
            
            flushinput(obj.client)
            
            while obj.client.BytesAvailable < length(obj.wait_signal)
            end
            
            received_string = fread(obj.client, length(obj.wait_signal), 'uchar');
            if strcmp(char(received_string)', obj.wait_signal)
                status = 0;
            else
                status = 1;
            end
        end
        
        
        function send_ready(obj)
            
            fwrite(obj.server, obj.wait_signal, 'uchar');
        end
        
        
        function send_message(obj, message)
            
            fwrite(obj.server, message, 'uchar');
        end
        
        
        function val = receive_message(obj)
            
            if obj.client.BytesAvailable > 0
                val = fread(obj.client, obj.client.BytesAvailable, 'uchar');
                val = char(val)';
            else
                val = [];
            end
        end
    end
end