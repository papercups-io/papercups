import React from 'react';
import {Box, Flex} from 'theme-ui';
import {debounce} from 'lodash';
import * as API from '../../api';
import {Issue} from '../../types';
import {AutoComplete} from '../common';
import {IssueStateTag} from './IssuesTable';
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
  options: Issue[];
};

class SearchIssuesInput extends React.Component<Props, State> {
  state: State = {
    options: [],
  };

  handleSelectIssue = (title: string, record: any) => {
    const {onSelectIssue} = this.props;
    const {options = []} = this.state;
    const {key: selectedIssueId} = record;
    const selectedIssue = selectedIssueId
      ? options.find((result) => result.id === selectedIssueId)
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
          options: issues.filter((issue) => {
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
    const {options} = this.state;

    return (
      <AutoComplete
        style={{width: '100%', ...style}}
        value={this.props.value}
        placeholder={this.props.placeholder || 'Search existing issues...'}
        onChange={this.props.onChange}
        onSelect={this.handleSelectIssue}
        onSearch={this.debouncedSearchIssues}
      >
        {options.map(({id, title, state}) => {
          return (
            <AutoComplete.Option key={id} value={`${title} (${state})`}>
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
