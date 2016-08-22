# Ported from: https://github.com/sosedoff/capistrano-unicorn/blob/master/lib/capistrano-unicorn/utility.rb

module Mina
  module Puma
    module Utility

      # Run a command as the :puma_user user if :puma_user is a string.
      # Otherwise run as default (:user) user.
      #
      def try_puma_user
        "sudo -u #{puma_user}" if puma_user.kind_of?(String)
      end

      # Check if a remote process exists using its pid file
      #
      def remote_process_exists?(pid_file)
        "[ -e #{pid_file} ] && #{try_puma_user} kill -0 `cat #{pid_file}` > /dev/null 2>&1"
      end

      # Stale Puma process pid file
      #
      def old_puma_pid
        "#{puma_pid}.oldbin"
      end

      # Command to check if Puma is running
      #
      def puma_is_running?
        remote_process_exists?(puma_pid)
      end

      # Command to check if stale Puma is running
      #
      def old_puma_is_running?
        remote_process_exists?(old_puma_pid)
      end

      # Get puma master process PID (using the shell)
      #
      def get_puma_pid(pid_file=puma_pid)
        "`cat #{pid_file}`"
      end

      # Get puma master (old) process PID
      #
      def get_old_puma_pid
        get_puma_pid(old_puma_pid)
      end

      # Send a signal to a puma master processes
      #
      def puma_send_signal(signal, pid=get_puma_pid)
        "#{try_puma_user} kill -s #{signal} #{pid}"
      end

      # Kill Pumas in multiple ways O_O
      #
      def kill_puma(signal)
        script = <<-END
          if #{puma_is_running?}; then
            echo "-----> Stopping Puma...";
            #{puma_send_signal(signal)};
          else
            echo "-----> Puma is not running.";
          fi;
        END

        script
      end

      # Start the Puma server
      #
      def start_puma
        %Q%
          if [ -e "#{puma_pid}" ]; then
            if #{try_puma_user} kill -0 `cat #{puma_pid}` > /dev/null 2>&1; then
              echo "-----> Puma is already running!";
              exit 0;
            fi;

            #{try_puma_user} rm #{puma_pid};
          fi;

          echo "-----> Starting Puma...";
          cd #{deploy_to}/#{current_path} && #{try_puma_user} #{puma_cmd} -d -C #{puma_config};
        %
      end

      # Restart the Puma server
      #
      def restart_puma
        %Q%
        #{duplicate_puma}

          sleep #{puma_restart_sleep_time}; # in order to wait for the (old) pidfile to show up

          if #{old_puma_is_running?}; then
            #{puma_send_signal('QUIT', get_old_puma_pid)};
          fi;
        %
      end

      def duplicate_puma
        %Q%
          if #{puma_is_running?}; then
            echo "-----> Duplicating Puma...";
            #{puma_send_signal('USR2')};
          else
            #{start_puma}
          fi;
        %
      end

    end
  end
end
