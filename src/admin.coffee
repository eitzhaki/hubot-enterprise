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


Promise = require 'bluebird'

module.exports = (robot) ->
  archive = new (require '../lib/archive')(robot.adapterName||'slack')

  robot.respond /admin archive channel (.*)/i, (msg) ->
    if msg.match[1]=='#general'
      msg.reply 'cannot archive #general channel'
      return
    if (msg.match[1]=='this')
      if (msg.envelope.message.user.room == msg.envelope.message.user.name || msg.envelope.message.user.room == 'general')
        msg.reply 'cannot archive private or general channel'
        return
      channelId = ['', msg.envelope.message.rawMessage.channel]
    else if (!msg.match[1].startsWith('#'))
      msg.reply 'channel name should start with #'
      return
    else if (!(channelId = /<\#(.*)>/i.exec(msg.envelope.message.rawText)))
      msg.reply 'could not find channel '+msg.match[1]
      return
    channelId = channelId[1]
    robot.logger.debug 'archiving channel: '+channelId
    msg.reply 'Yes sir!'
    archive.archive_channel(robot, msg, channelId)
      .then (r) ->
        msg.reply 'done'
      .catch (e) ->
        robot.logger.error e
        msg.reply 'Error: '+e

  robot.respond /admin archive older ([0-9]+)([dDhHmMsS]) ?(.*)/i, (msg) ->
    room = msg.message.room
    type = 'name'
    seconds = switch
      when msg.match[2]=='d' then msg.match[1]*86400
      when msg.match[2]=='h' then msg.match[1]*3600
      when msg.match[2]=='m' then msg.match[1]*60
      when msg.match[2]=='s' then msg.match[1]
    # currently hardcoded patterns
    if (msg.match[3] &&
    (pattern_option = /(named|topic) (.*)/i.exec(msg.match[3])))
      patterns = []
      HUBOT_ADMIN_CHANNEL_MIN = process.env.HUBOT_ADMIN_CHANNEL_MIN || 3
      if pattern_option[1] == 'topic'
        type = 'topic'
      for arg in pattern_option[2].split(process.env.HUBOT_ADMIN_OR || ' or ')
        if arg.length > HUBOT_ADMIN_CHANNEL_MIN
          patterns.push arg
        else
          msg.reply 'Channel prefix "'+arg+'" is too short, '+
            'should be at least '+HUBOT_ADMIN_CHANNEL_MIN+' characters long'
    else
      patterns = ['advantage', 'incident']
    if patterns.length == 0
      msg.reply 'no patterns to archive :disappointed:'
      return
    msg.reply 'archiving channels with pattern: "'+patterns.join('", "')+
      '" older than '+msg.match[1]+msg.match[2]+' by '+type
    archive.archive_old(robot, msg, seconds, patterns, room, type)
      .then (r) ->
        robot.logger.debug 'back from Promise', r
        msg.reply 'done, total archived: '+r.totalArchived
