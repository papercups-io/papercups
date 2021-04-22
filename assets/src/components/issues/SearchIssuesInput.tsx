import React from 'react';
import {Box, Flex} from 'theme-ui';
import {debounce} from 'lodash';
import * as API from '../../api';
import {Issue} from '../../types';
import {AutoComplete} from '../common';
import {IssueStateTag} from '../issues/IssuesOverview';
import logger from '../../logger';

type Props = {
  placeholder?: string;
  value?: string;
  ignored?: Array<Issue>;
  style?: any;
  onChange: (query: string, record: any) => void;
  onSelectIssue?: (issue: Issue) => void;
};
type State = {
  issueSearchResults: Issue[];
  selectedIssueId: string | undefined;
  selectedIssueTitle: string | undefined;
};

class SearchIssuesInput extends React.Component<Props, State> {
  state: State = {
    issueSearchResults: [],
    selectedIssueId: undefined,
    selectedIssueTitle: undefined,
  };

  handleSelectIssue = (title: string, record: any) => {
    const {onSelectIssue} = this.props;
    const {issueSearchResults = []} = this.state;
    const {key: selectedIssueId} = record;
    const selectedIssue = selectedIssueId
      ? issueSearchResults.find((result) => result.id === selectedIssueId)
      : null;

    if (selectedIssue && typeof onSelectIssue === 'function') {
      onSelectIssue(selectedIssue);
    }
  };

  handleSearchIssues = (query?: string) => {
    const {ignored = []} = this.props;

    API.fetchAllIssues({q: query})
      .then((issues) => {
        this.setState({
          issueSearchResults: issues.filter((issue) => {
            return !ignored.some((i) => i.id === issue.id);
          }),
        });
      })
      .catch((err) => logger.error('Error searching issues:', err));
  };

  debouncedSearchIssues = debounce(
    (query: string) => this.handleSearchIssues(query),
    400
  );

  render() {
    const {style = {}} = this.props;
    const {issueSearchResults} = this.state;

    return (
      <AutoComplete
        style={{width: '100%', ...style}}
        value={this.props.value}
        placeholder={this.props.placeholder || 'Search existing issues...'}
        onChange={this.props.onChange}
        onSelect={this.handleSelectIssue}
        onSearch={this.debouncedSearchIssues}
      >
        {issueSearchResults.map(({id, title, state}) => {
          return (
            <AutoComplete.Option key={id} value={title}>
              <Flex sx={{alignItems: 'center'}}>
                <Box mr={2}>{title}</Box>
                <IssueStateTag state={state} />
              </Flex>
            </AutoComplete.Option>
          );
        })}
      </AutoComplete>
    );
  }
}

export default SearchIssuesInput;
