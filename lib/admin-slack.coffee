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


# admin actions for Slack

Querystring = require 'querystring'
SlackApi = require './slack_web_api'
Promise = require 'bluebird'
_ = require 'lodash'
class AdminExt
  constructor: (apiToken = process.env.SLACK_APP_TOKEN) ->
    @apiToken = apiToken

  setTopic: (channelId, topic)->
    opts =
      token: @apiToken
      channel: channelId
      topic: topic
    SlackApi.channels.setTopic opts

  join: (channelName) ->
    opts =
      token: @apiToken
      name: channelName
    SlackApi.channels.join opts

  archive: (channelId) ->
    opts =
      token: @apiToken
      channel: channelId
    SlackApi.channels.archive opts

  rename: (channelId, channelName) ->
    opts =
      token: @apiToken
      channel: channelId
      name: channelName
    SlackApi.channels.rename opts

  channelList: (excludeArchived) ->
    opts =
      token: @apiToken
      exclude_archived: excludeArchived
    return SlackApi.channels.list(opts)
      .then (r) ->
        return r.channels

  channelInfo: (channelId) ->
    opts =
      token: @apiToken
      channel: channelId
    return SlackApi.channels.info(opts)
      .then (r) ->
        return r.channel

module.exports = AdminExt
