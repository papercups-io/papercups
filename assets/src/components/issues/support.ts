export const isValidGithubUrl = (url: string): boolean => {
  return url.indexOf('github.com/') !== -1;
};

export const getGithubIssueUrlPath = (url: string) => {
  const [, githubIssuePath] = url.split('github.com/');

  return githubIssuePath;
};

export const isValidGithubIssueUrl = (url: string): boolean => {
  if (!isValidGithubUrl(url)) {
    return false;
  }

  const str = getGithubIssueUrlPath(url);
  // Check that the path looks like "/owner/repo/issues/123"
  const [, , issues, num] = str.split('/');

  return issues === 'issues' && !!Number(num);
};
