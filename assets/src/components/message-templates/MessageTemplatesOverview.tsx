import React from 'react';
import {RouteComponentProps} from 'react-router-dom';
import {Box, Flex} from 'theme-ui';
import qs from 'query-string';

import {Button, Container, Input, Paragraph, Title} from '../common';
import {PlusOutlined} from '../icons';
import * as API from '../../api';
import {MessageTemplate} from '../../types';
import MessageTemplatesTable from './MessageTemplatesTable';
import logger from '../../logger';
import {NewMessageTemplateModalButton} from './NewMessageTemplateModal';

type Props = RouteComponentProps<{}>;
type State = {
  filterQuery: string;
  filteredMessageTemplates: Array<MessageTemplate>;
  loading: boolean;
  broadcastId: string | null;
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
    broadcastId: null,
    loading: true,
    messageTemplates: [],
  };

  async componentDidMount() {
    const q = qs.parse(this.props.location.search);
    const broadcastId = q.bid ? String(q.bid) : null;

    this.setState({broadcastId});

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

  handleNewMessageTemplate = (template: MessageTemplate) => {
    this.props.history.push(
      `/message-templates/${template.id}${this.props.location.search}`
    );
  };

  handleSelectTemplate = (id: string) => {
    const {broadcastId} = this.state;

    if (!broadcastId) {
      return;
    }

    API.updateBroadcast(broadcastId, {message_template_id: id}).then(() =>
      this.props.history.push(`/broadcasts/${broadcastId}`)
    );
  };

  render() {
    const {loading, broadcastId, filteredMessageTemplates = []} = this.state;

    return (
      <Container>
        <Flex sx={{justifyContent: 'space-between', alignItems: 'center'}}>
          <Title level={3}>Message Templates</Title>

          <NewMessageTemplateModalButton
            type="primary"
            icon={<PlusOutlined />}
            onSuccess={this.handleNewMessageTemplate}
          >
            New message template
          </NewMessageTemplateModalButton>
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
            isSelectEnabled={!!broadcastId}
            messageTemplates={filteredMessageTemplates}
            onSelect={this.handleSelectTemplate}
          />
        </Box>
      </Container>
    );
  }
}

export default MessageTemplatesOverview;
