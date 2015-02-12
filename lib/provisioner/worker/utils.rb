#!/usr/bin/env ruby
# encoding: UTF-8
#
# Copyright © 2012-2015 Cask Data, Inc.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

require 'net/scp'

class SignalHandler
  def initialize(signal)
    @interuptable = false
    @enqueued     = []
    trap(signal) do
      if @interuptable
        log.info 'Gracefully shutting down provisioner...'
        exit 0
      else
        @enqueued.push(signal)
      end
    end
  end

  # If this is called with a block then the block will be run with
  # the signal temporarily ignored. Without the block, we'll just set
  # the flag and the caller can call `allow_interuptions` themselves.
  def dont_interupt
    @interuptable = false
    @enqueued     = []
    # rubocop:disable GuardClause
    if block_given?
      yield
      allow_interuptions
    end
    # rubocop:enable GuardClause
  end

  def allow_interuptions
    @interuptable = true
    # Send the temporarily ignored signals to ourself
    # see http://www.ruby-doc.org/core/classes/Process.html#M001286
    @enqueued.each { |signal| Process.kill(signal, Process.pid) }
  end
end

# Exception class used to return remote command stderr
class CommandExecutionError < RuntimeError
  attr_reader :command, :stdout, :stderr, :exit_code, :exit_signal

  def initialize(command, stdout, stderr, exit_code, exit_signal)
    @command = command
    @stdout = stdout
    @stderr = stderr
    @exit_code = exit_code
    @exit_signal = exit_signal
  end

  def to_json(*a)
    result = {
      "message" => message,
      "command" => command,
      "stdout" => @stdout,
      "stderr" => @stderr,
      "exit_code" => @exit_code,
      "exit_signal" => @exit_signal
    }
    result.to_json(*a)
  end
end

def ssh_exec!(ssh, command, message = command, pty = false)
  stdout_data = ''
  stderr_data = ''
  exit_code = nil
  exit_signal = nil
  log.debug message if message != command
  log.debug "---ssh-exec command: #{command}"
  ssh.open_channel do |channel|
    if pty
      channel.request_pty do |ch, success|
        raise "no pty!" if !success
      end
    end
    channel.exec(command) do |ch, success|
      unless success
        abort "FAILED: couldn't execute command (ssh.channel.exec)"
      end
      channel.on_data do |ch, data|
        stdout_data += data
      end

      channel.on_extended_data do |ch, type, data|
        stderr_data += data
      end

      channel.on_request('exit-status') do |ch, data|
        exit_code = data.read_long
      end

      channel.on_request('exit-signal') do |ch, data|
        exit_signal = data.read_long
      end
    end
  end
  ssh.loop

  log.debug "stderr: #{stderr_data}"
  log.debug "stdout: #{stdout_data}"

  fail CommandExecutionError.new(command, stdout_data, stderr_data, exit_code, exit_signal), message unless exit_code == 0

  [stdout_data, stderr_data, exit_code, exit_signal]
end
