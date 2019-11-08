# jira.vim

This is a JIRA plugin for Vim to browse issues, allowing for custom JQL.  While definitely a work in progress it does render information at least. :D

## Atlassian API

This uses the new Atlassian Cloud API, so you need to generate yourself an [https://confluence.atlassian.com/cloud/api-tokens-938839638.html](API key).

You will then override one of the variables/optoins.

## Installation

Truly only tested w/ vim-plug:

```
Plug 'eric-hansen/vim-jira'
```

## Dependencies

This extension was made to be as dependent-free as possible, but it does depend on 2 different things:

* An Atlassian API key which was stated above
* cURL installed and executable from within Vim

## First-Time Use

The only 2 options that are required are `g:jira_browser_domain` and `g:jira_browser_authfile`.  The domain needs to be the FQDN currently, so if you access JIRA by https://company.atlassian.net/... then set this to `company.atlassian.net`.  This may change in the future but for now it is what it is. :)

There are a few other options that are configurable as well but not mandatory.  `g:jira_browser_authfile` is recommended to be changed since it writes to /tmp by default, but not required.

Once you set the above you just call the function `:call jira#getTickets()` or bind it to a key.

## Keymappings

There's no keymapping specific to this plugin yet.  There may in the future, especially if I end up making this more advanced.  But one step at a time.

## Options

### g:jira_browser_domain

The domain for your Atlassian cloud set up.  Right now requires the full TLD (i.e.: company.atlassian.net).

*Default*: ''

### g:jira_browser_authfile

The file to write out the username + API token combo.  Required as the file is read each request.

*Default*: '/tmp/jira'

### g:jira_browser_ticket_template

The template for each ticket when parsing.  Different "tags" are surrounded by {} as "{ticket}" will be replaced with the proper data.

*Default*: "{ticket} - {summary} [{priority} - {status}]\n{description}"

### g:jira_browser_ticket_fields

A dictionary of "tag" -> "issue prop".  This kind of requires seeing a full issue object from Atlassian but basically this correlates to the fields you want to see.  The default is not exhaustive but provides a good foundation to start with.  There is a caveat though which will be discussed with the parsers.

*Default*: {'ticket': 'key', 'description': 'description', 'summary': 'summary', 'priority': 'priority', 'type': 'issuetype', 'fixedin': 'fixedVersions', 'status': 'status', 'createdby': 'creator'}

### g:jira_browser_project_keys

A list of project keys to query within.  Refines the search internally for JIRA.  In JQL use "{jiraProjects}" for where this list should be placed.  Even if there is only 1 project to filter on, it must be a list.

*Default*: []

### g:jira_browser_default_jql

If no JQL is explicitly passed into jira#getTickets() then this JQL is used instead.

*Default*: "project IN ({jiraProjects}) AND assignee = currentUser() AND resolution = Unresolved AND Sprint in openSprints() ORDER BY updated DESC, priority DESC"

### g:jira_browser_debug

When set to 1 will print out verbose data into messages buffer.

*Deault*: 0

### g:jira_browser_ticket_parsers

The work horse of this project.  A dictionary of "tag" -> "parser function".  As mentioned earlier there is a caveat with how this plugin is developed.

If there is no parser function passed in, then it will attempt to fetch the value from the issue itself.  So if you have an issue object like so:

```
{
  "key": "ABC-123",
  "fields": {
    "priority": {
      "name": "Medium"
    }
  }
}
```

With a parsers object set up like this:

```
{
  "key": "",
  "priority": ""
}
```

Then the ticket template will populate `{key}` with `ABC-123` but `{priority}` will be 0 because 1) priority is within `fields` and 2) priority is an object.

Instead, to parse priority you would do something like:

```
function! jira#getPriority(issue)
  return get(get(get(a:issue, 'fields'), 'priority'), 'name')
endfunction
```

You would then set "priority" key in the parsers object to `jira#getPriority`.  See `autoload/jira.vim` for other parsers.

*Default*: 
```
let g:jira_browser_ticket_parsers = {
      \ 'summary': 'jira#getSummary',
      \ 'description': 'jira#getDescription',
      \ 'priority': 'jira#getPriority',
      \ 'type': '',
      \ 'fixedin': '',
      \ 'status': 'jira#getStatus',
      \ 'createdby': ''
      \ }
```

## Functions

### jira#getTickets

The function to call to run the JQL and get any tickets/issues that match the JQL.

It takes a variable list of arguments:

* 1st argument - custom JQL (i.e.: `key = DEF-456`).  If not `''` will override the default JQL for this call only
* 2nd argument - # of max results you want rendered.  Default is whatever Atlassian is configured for.  Set to -1 to keep the default for this request
* 3rd argument - Array list of fields to return for this request only.  Set to an empty [] to keep the default from `g:jira_browser_ticket_fields`

This function calls Atlassian via cURL and then parses the responding JSON.  If there's an error it will spit that out, otherwise it will construct a read-only buffer to render the generated output.  If you're curious on how the 2nd part works, look at s:jira#parseTicketTemplate.

### jira#saveAuth

You can either call this as `jira#saveAuth('username', 'api-key')` directly or write the data as `username:api-key` to wherever `g:jira_browser_authfile` is pointing to, as that's all it does.  But this needs to be set, along with `g:jira_browser_domain` before you can use this plugin.

### Parser Functions

Parser functions need to be accessible from the plugin, so `s:*` or `l:*` most likely won't work (not tested but not going to support either :D).  They must accept 1 parameter only, and that is `issue` representing the current issue being parsed.  See `autoload/jira.vim` to see how these are written.  Most are simple, but `jira#getDescription` is a little bit more advanced.

## To Do

This plugin is by far a work in progress.  There are many features missing from this that would make it more useful.  Below is a non-exhaustive list:

* Support more description types such as media
* Render the full issue link
* Better syntax highlighting
* Investigate supporting dynamic syntax highlighting (so issue keys can be highlighted)
* Allow commenting on tickets as well
* Perhaps make it a window instead of a buffer
* Make the issue template dynamic (based on project key)
* When viewing a single ticket, render comments as well
* Make async with the cURL calling so as to not hang Vim
