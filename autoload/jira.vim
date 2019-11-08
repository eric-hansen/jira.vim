function! jira#saveAuth(username, apiToken)
  call writefile([a:username . ':' . a:apiToken], expand(g:jira_browser_authfile))
endfunction

function! jira#curlCall(method, uri, postdata)
  let authToken = readfile(expand(g:jira_browser_authfile))[0]

  let authHeaders = '-H "X-Atlassian-Token:no-check" --user "' . authToken .'"'
  let bodyData = a:postdata != {} ? "-d '" . json_encode(a:postdata) . "'" : ''
  let url = 'https://' . g:jira_browser_domain . '/rest/api/3/' . a:uri

  let curl = 'curl -ss ' . authHeaders .' -H "Content-Type:application/json" ' . bodyData . ' ' . url

"  if g:jira_browser_debug == 1
    echom 'curl command: ' . curl
"  endif

  let data = json_decode(system(curl))

  if get(data, 'errorMessages', []) != []
    let err = "Error fetching JIRA data:\n" . join(get(data, 'errorMessages'), "\n")
    echom err
    return {}
  else
    return data
  endif
endfunction

function! jira#getTickets(...)
  let customJql = get(a:000, 0, '')
  let maxResults = get(a:000, 1, -1)
  let customFields = get(a:000, 2, -1)

  let body = {}

  let body.jql = customJql != '' ? customJql : g:jira_browser_default_jql

  let body.jql = substitute(body.jql, '{jiraProjects}', join(g:jira_browser_project_keys, ','), 0)

  if maxResults != -1
    let body.maxResults = maxResults
  endif

  if customFields != -1
    let body.fields = customFields
  else 
    let body.fields = ["self", "key", "summary", "status", "creator", "issuetype","description", "fixVersions", "priority"]
  endif
  
  let jira_tickets = jira#curlCall('POST', 'search', body)

  let issues = get(jira_tickets, 'issues', [])

  if issues != []
    call s:jira#parseTicketTemplate(issues)
  endif
endfunction

function! jira#getDescription(issue) abort
  let description = get(get(a:issue, 'fields'), 'description')
  let content = []

  if description is v:null
    return ''
  endif

  let contentElements = get(description, 'content')

  let result = ''

  for content in contentElements
    for item in get(content, 'content')
      let contentType = get(item, 'type')

      if contentType == 'text'
        let result = result . get(item, 'text') . "\n"
      elseif contentType == 'hardbreak'
        let result = result . "\n"
      elseif contentType == 'mention'
        let result .= get(get(item, 'attrs'), 'text') . " "
      else
        echom 'No handler for content type ' . contentType
      endif
    endfor
  endfor

  return result
endfunction

function! jira#getSummary(issue)
  return get(get(a:issue, 'fields'), 'summary')
endfunction

function! jira#getStatus(issue)
  echo get(get(a:issue, 'fields'), 'status')
  return get(get(get(a:issue, 'fields'), 'status'), 'name')
endfunction

function! jira#getPriority(issue)
  return get(get(get(a:issue, 'fields'), 'priority'), 'name')
endfunction

function! s:jira#parseTicketTemplate(tickets)
  let buffmsg = ''

  let fields = g:jira_browser_ticket_fields
  let parsers = g:jira_browser_ticket_parsers

  for ticket in a:tickets
    let msg = g:jira_browser_ticket_template

    for prop in keys(fields)
      let l:funcName = get(parsers, prop, '')
      let l:propValue = get(ticket, get(fields, prop))
      
      if g:jira_browser_debug == 1
        echo 'Looking for prop parser ' . l:funcName . ' for prop ' . prop
      endif

      if l:funcName != '' && exists('*' . l:funcName)
        let Func = function(l:funcName)
        let l:propValue = Func(ticket)
      endif
      
      let msg = substitute(msg, '{' . prop . '}', l:propValue, 0)
    endfor

    let buffmsg .= msg . "\n\n"
  endfor

  if buffmsg != ''
    execute 'new' 'jira'
    setlocal modifiable
    silent %delete _

    call setline(1, split(buffmsg, "\n"))

    setlocal nomodified readonly nomodifiable buftype=nofile bufhidden=wipe filetype=jira
  else
    echom "No JIRA tickets to display"
  endif
endfunction


