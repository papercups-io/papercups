import React from 'react';
import {Box, Flex} from 'theme-ui';
import {Button, Container, Input, Paragraph, Title} from '../common';
import {PlusOutlined} from '../icons';
import * as API from '../../api';
import {MessageTemplate} from '../../types';
import MessageTemplatesTable from './MessageTemplatesTable';
import logger from '../../logger';

type Props = {};
type State = {
  filterQuery: string;
  filteredMessageTemplates: Array<MessageTemplate>;
  loading: boolean;
  messageTemplates: Array<MessageTemplate>;
};

const filterMessageTemplatesByQuery = (
  messageTemplates: Array<MessageTemplate>,
  query?: string
): Array<MessageTemplate> => {
  if (!query || !query.length) {
    return messageTemplates;
  }

  return messageTemplates.filter((messageTemplate) => {
    const {id, name, description} = messageTemplate;

    const words = [id, name, description]
      .filter((str) => str && String(str).trim().length > 0)
      .join(' ')
      .replace('_', ' ')
      .split(' ')
      .map((str) => str.toLowerCase());

    const queries = query.split(' ').map((str) => str.toLowerCase());

    return queries.every((q) => {
      return words.some((word) => word.indexOf(q) !== -1);
    });
  });
};

class MessageTemplatesOverview extends React.Component<Props, State> {
  state: State = {
    filteredMessageTemplates: [],
    filterQuery: '',
    loading: true,
    messageTemplates: [],
  };

  async componentDidMount() {
    await this.handleRefreshMessageTemplates();
  }

  handleSearchMessageTemplates = (filterQuery: string) => {
    const {messageTemplates = []} = this.state;

    if (!filterQuery?.length) {
      this.setState({
        filterQuery: '',
        filteredMessageTemplates: messageTemplates,
      });
    }

    this.setState({
      filterQuery,
      filteredMessageTemplates: filterMessageTemplatesByQuery(
        messageTemplates,
        filterQuery
      ),
    });
  };

  handleRefreshMessageTemplates = async () => {
    try {
      const {filterQuery} = this.state;
      const messageTemplates = await API.fetchMessageTemplates();

      this.setState({
        filteredMessageTemplates: filterMessageTemplatesByQuery(
          messageTemplates,
          filterQuery
        ),
        loading: false,
        messageTemplates,
      });
    } catch (err) {
      logger.error('Error loading message templates!', err);

      this.setState({loading: false});
    }
  };

  render() {
    const {loading, filteredMessageTemplates = []} = this.state;

    return (
      <Container>
        <Flex sx={{justifyContent: 'space-between', alignItems: 'center'}}>
          <Title level={3}>Message Templates</Title>

          <Button type="primary" icon={<PlusOutlined />}>
            New message template
          </Button>
        </Flex>

        <Box mb={4}>
          <Paragraph>
            Create dynamic messages to use as templates for broadcasting emails
            and other notifications to your customers.
          </Paragraph>
        </Box>

        <Box mb={3}>
          <Input.Search
            placeholder="Search templates..."
            allowClear
            onSearch={this.handleSearchMessageTemplates}
            style={{width: 400}}
          />
        </Box>

        <Box my={4}>
          <MessageTemplatesTable
            loading={loading}
            messageTemplates={filteredMessageTemplates}
          />
        </Box>
      </Container>
    );
  }
}

export default MessageTemplatesOverview;
