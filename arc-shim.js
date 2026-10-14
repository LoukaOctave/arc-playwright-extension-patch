// Arc patch: Arc has no tab groups, and its tab group calls never settle, which stalls the connect flow.
// Fail them fast; every caller already catches the error.
for (const [api, name] of [[chrome.tabs, "group"], [chrome.tabs, "ungroup"], [chrome.tabGroups, "query"], [chrome.tabGroups, "update"]]) {
	api[name] = () => Promise.reject(new Error("Tab groups are not supported in Arc"));
}
