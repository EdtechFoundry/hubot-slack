MESSAGE_RESERVED_KEYWORDS = ['channel','group','everyone','here']


# https://api.slack.com/docs/formatting
class SlackFormatter

  constructor: (@dataStore) ->


  ###
  Formats links and ids
  ###
  links: (text) ->    
    regex = ///
      <              # opening angle bracket
      ([@#!])?       # link type
      ([^>|]+)       # link
      (?:\|          # start of |label (optional)
      ([^>]+)        # label
      )?             # end of label
      >              # closing angle bracket
    ///g

    text = text.replace regex, (m, type, link, label) =>
      switch type

        when '@'
          if label then return label
          user = @dataStore.getUserById link
          if user
            return "@#{user.name}"

        when '#'
          # commented out label as it strips away links for channels
          #if label then return label
          channel = @dataStore.getChannelById link
          if channel
            return "\##{channel.name}"

        when '!'
          if link in MESSAGE_RESERVED_KEYWORDS
            return "@#{link}"

        else
          link = link.replace /^mailto:/, ''
          if label and -1 == link.indexOf label
            "#{label} (#{link})"
          else
            link

    text = text.replace /&lt;/g, '<'
    text = text.replace /&gt;/g, '>'
    text = text.replace /&amp;/g, '&'


  ###
  Flattens message text and attachments into a multi-line string
  ###
  flatten: (message) ->
    text = []

    # basic text messages
    text.push(message.text) if message.text

    # append all attachments
    for attachment in message.attachments or []
      text.push(attachment.fallback)    

    # flatten array
    text.join('\n')


  ### 
  Recursively replace @username with <@UXXXXX> for mentioning users and channels
  ###
  mentions: (text) ->
    return if text is null # nothing to do
      
    if typeof text is 'string'
      text.replace /(?:^| )@([\w\.-]+)/gm, (match, username) =>
        user = @dataStore.getUserByName(username)
        if user
          match = match.replace /@[\w\.-]+/, "<@#{user.id}>"
        else if username in MESSAGE_RESERVED_KEYWORDS
          match = match.replace /@[\w\.-]+/, "<!#{username}>"
        else
          match #do nothing if we don't revognize the name

    # object passed in, parse each property recursively
    else if typeof text is 'object'
      for key, value of text
        text[key] = @mentions(value)
      text

    # we got something else, just pass it back out.
    else
      text


  ###
  Formats an incoming Slack message
  ###
  incoming: (message) ->
    @links @flatten message


  ###
  Formats outgoing messages
  ###
  outgoing: (message) ->
    @mentions message


module.exports = SlackFormatter
