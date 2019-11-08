let g:jira_browser_domain=''
let g:jira_browser_authfile='/tmp/jira'
let g:jira_browser_ticket_template="{ticket} - {summary} [{priority} - {status}]\n{description}"
let g:jira_browser_ticket_fields = {'ticket': 'key', 'description': 'description', 'summary': 'summary', 'priority': 'priority', 'type': 'issuetype', 'fixedin': 'fixedVersions', 'status': 'status', 'createdby': 'creator'}
let g:jira_browser_project_keys = []
let g:jira_browser_default_jql = 'project IN ({jiraProjects}) AND assignee = currentUser() AND resolution = Unresolved AND Sprint in openSprints() ORDER BY updated DESC, priority DESC'
let g:jira_browser_debug = 0

let g:jira_browser_ticket_parsers = {
      \ 'summary': 'jira#getSummary',
      \ 'description': 'jira#getDescription',
      \ 'priority': 'jira#getPriority',
      \ 'type': '',
      \ 'fixedin': '',
      \ 'status': 'jira#getStatus',
      \ 'createdby': ''
      \ }

