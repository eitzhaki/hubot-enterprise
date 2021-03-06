###
Copyright 2016 Hewlett-Packard Development Company, L.P.

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing,
Software distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and limitations under the License.
###


#AdminExt = require './admin-slack'
Promise = require 'bluebird'
moment = require 'moment'
ARCH_PREFIX = 'ARCH-'
#adapter = new AdminExt()

class Archive
  constructor: (adapter) ->
    @adapter = new (require './admin-'+(adapter||'slack'))()

  sort_channels: (robot, channels, current, regex, type) ->
    ret = []
    type = type || 'name'
    for channel in channels
      to_test = if (type == 'name') then channel.name else channel.topic.value
      if regex.test(to_test) && channel.name!=current
        robot.logger.debug to_test
        ret.push channel
    return ret

  archive_single: (robot, msg, channel) ->
    robot.logger.debug channel
    robot.logger.debug 'joining'
    _adapter = @adapter
    return _adapter.join(channel.name)
      .then (r) ->
        robot.logger.debug 'join: '+r+', -> setTopic'
        return _adapter.setTopic(channel.id, channel.name)
      .then (r) ->
        robot.logger.debug 'setTopic: '+r+' , -> archive'
        return _adapter.archive(channel.id)
      .then (r) ->
        robot.logger.debug 'archive: '+r+', -> rename'
        return _adapter.rename(channel.id, ARCH_PREFIX+Date.now())
      .then (r) ->
        robot.logger.debug 'rename: '+r+', -> BACK'
        msg.reply 'archived channel: '+channel.name+' ('+channel.id+'), '+
          'created '+moment(channel.created*1000).fromNow()
        return channel.name

  archive_channel: (robot, msg, channel) ->
    _adapter = @adapter
    _this = this
    return _adapter.channelInfo(channel)
      .then (r) ->
        return _this.archive_single(robot, msg, r)

  archive_old: (robot, msg, seconds, patterns, thisChannel, type) ->
    _this = this
    totalArchived = 0
    type = type || 'name'
    channelPatterns = new RegExp('('+(patterns.join '|')+')', 'i')
    now = Math.floor(Date.now()/1000)
    robot.logger.debug 'Archiving older than :'+seconds+' seconds'
    return @adapter.channelList(true)
      .then (r) ->
        channels = _this.sort_channels robot, r, thisChannel, channelPatterns,
          type
        return Promise.map(channels, (channel) ->
          robot.logger.debog
          create_time = Math.floor(now - channel.created)
          robot.logger.debug 'Channel: '+channel.name+' Create elapsed time: '+
            create_time+' created time: '+channel.created
          if create_time > seconds
            robot.logger.debug 'archiving '+channel.name+' '+channel.id+
              ' ('+create_time+')'
            return _this.archive_single(robot, msg, channel)
              .then (r) ->
                totalArchived++
                return r
        )
      .then (r) ->
        robot.logger.debug 'MAP DONE'
        r.totalArchived = totalArchived
        return r
      .catch (r) ->
        robot.logger.debug r
module.exports = Archive
