import React from 'react';
import {Link} from 'react-router-dom';
import {Box, Flex} from 'theme-ui';
import dayjs from 'dayjs';
import utc from 'dayjs/plugin/utc';
import {
  Button,
  colors,
  Content,
  Layout,
  Result,
  Sider,
  Text,
  Title,
} from '../common';
import {SmileOutlined} from '../icons';
import Spinner from '../Spinner';
import ChatMessage from './ChatMessage';
import ConversationHeader from './ConversationHeader';
import ConversationItem from './ConversationItem';
import ConversationFooter from './ConversationFooter';

dayjs.extend(utc);

const formatMessage = (message: any) => {
  return {
    ...message,
    sender: message.customer_id ? 'customer' : 'agent',
  };
};

const EmptyMessagesPlaceholder = () => {
  return (
    <Box my={4}>
      <Result
        status="success"
        title="No messages"
        subTitle="Nothing to show here! Take a well-earned break 😊"
      />
    </Box>
  );
};

const GettingStartedRedirect = () => {
  return (
    <Box my={4}>
      <Result
        icon={<SmileOutlined />}
        title="No messages"
        subTitle="It looks like your widget hasn't been set up yet!"
        extra={
          <Link to="/account/getting-started">
            <Button type="primary">Get Started</Button>
          </Link>
        }
      />
      ,
    </Box>
  );
};

type Props = {
  title?: string;
  account: any;
  currentUser: any;
  loading: boolean;
  showGetStarted: boolean;
  selectedConversationId: string | null;
  conversationIds: Array<string>;
  conversationsById: {[key: string]: any};
  messagesByConversation: {[key: string]: any};
  fetch: () => Promise<Array<string>>;
  onSelectConversation: (id: string, fn: () => void) => void;
  onUpdateConversation: (id: string, params: any) => void;
  onSendMessage: (message: string, fn: () => void) => void;
};

type State = {loading: boolean; selected: string | null};

class ConversationsContainer extends React.Component<Props, State> {
  scrollToEl: any = null;

  state: State = {loading: true, selected: null};

  componentDidMount() {
    this.props
      .fetch()
      .then(() => this.setState({loading: false}))
      .then(() => this.scrollToEl.scrollIntoView());
  }

  handleSelectConversation = (id: string) => {
    this.props.onSelectConversation(id, () => {
      this.scrollToEl.scrollIntoView();
    });
  };

  handleCloseConversation = (conversationId: string) => {
    this.props.onUpdateConversation(conversationId, {status: 'closed'});
  };

  handleReopenConversation = (conversationId: string) => {
    this.props.onUpdateConversation(conversationId, {status: 'open'});
  };

  handleMarkPriority = (conversationId: string) => {
    this.props.onUpdateConversation(conversationId, {priority: 'priority'});
  };

  handleMarkUnpriority = (conversationId: string) => {
    this.props.onUpdateConversation(conversationId, {
      priority: 'not_priority',
    });
  };

  handleAssignUser = (conversationId: string, userId: string) => {
    this.props.onUpdateConversation(conversationId, {assignee_id: userId});
  };

  handleSendMessage = (message: string) => {
    this.props.onSendMessage(message, () => this.scrollToEl.scrollIntoView());
  };

  render() {
    const {
      title,
      account,
      currentUser,
      showGetStarted,
      selectedConversationId,
      conversationIds = [],
      conversationsById = {},
      messagesByConversation = {},
    } = this.props;
    const users = (account && account.users) || [];

    const messages = selectedConversationId
      ? messagesByConversation[selectedConversationId]
      : [];
    const selectedConversation = selectedConversationId
      ? conversationsById[selectedConversationId]
      : null;

    const loading = this.props.loading || this.state.loading;

    return (
      <Layout style={{background: colors.white}}>
        <Sider
          theme="light"
          width={280}
          style={{
            borderRight: '1px solid #f0f0f0',
            overflow: 'auto',
            height: '100vh',
            position: 'fixed',
            left: 220,
          }}
        >
          <Box p={3} sx={{borderBottom: '1px solid #f0f0f0'}}>
            <Title level={3} style={{marginBottom: 0, marginTop: 8}}>
              {title || 'Conversations'}
            </Title>
          </Box>

          <Box>
            {conversationIds.length ? (
              conversationIds.map((conversationId, idx) => {
                const conversation = conversationsById[conversationId];
                const messages = messagesByConversation[conversationId];
                const isHighlighted = conversationId === selectedConversationId;
                const {gold, red, green, gray} = colors;
                // TODO: come up with a better way to make colors/avatars consistent
                const color = [gold, red, green, gray[0]][idx % 4];

                return (
                  <ConversationItem
                    key={conversationId}
                    conversation={conversation}
                    messages={messages}
                    isHighlighted={isHighlighted}
                    color={color}
                    onSelectConversation={this.handleSelectConversation}
                  />
                );
              })
            ) : (
              <Box p={3}>
                <Text type="secondary">
                  {loading ? 'Loading...' : 'No conversations'}
                </Text>
              </Box>
            )}
          </Box>
        </Sider>
        <Layout style={{marginLeft: 280, background: colors.white}}>
          <ConversationHeader
            conversation={selectedConversation}
            users={users}
            onAssignUser={this.handleAssignUser}
            onMarkPriority={this.handleMarkPriority}
            onRemovePriority={this.handleMarkUnpriority}
            onCloseConversation={this.handleCloseConversation}
            onReopenConversation={this.handleReopenConversation}
          />

          <Content style={{overflowY: 'scroll'}}>
            {loading ? (
              <Flex
                sx={{
                  flex: 1,
                  justifyContent: 'center',
                  alignItems: 'center',
                  height: '100%',
                }}
              >
                <Spinner size={40} />
              </Flex>
            ) : (
              <Box
                p={4}
                backgroundColor={colors.white}
                sx={{minHeight: '100%'}}
              >
                {messages.length ? (
                  messages.map((message: any, key: number) => {
                    // Slight hack
                    const msg = formatMessage(message);
                    const next = messages[key + 1];
                    const isMe = msg.user_id && msg.user_id === currentUser.id;
                    const isLastInGroup = next
                      ? msg.customer_id !== next.customer_id
                      : true;

                    // TODO: fix `isMe` logic for multiple agents
                    return (
                      <ChatMessage
                        key={key}
                        message={msg}
                        isMe={isMe}
                        isLastInGroup={isLastInGroup}
                        shouldDisplayTimestamp={isLastInGroup}
                      />
                    );
                  })
                ) : showGetStarted ? (
                  <GettingStartedRedirect />
                ) : (
                  <EmptyMessagesPlaceholder />
                )}
                <div ref={(el) => (this.scrollToEl = el)} />
              </Box>
            )}
          </Content>

          {selectedConversation && (
            <ConversationFooter onSendMessage={this.handleSendMessage} />
          )}
        </Layout>
      </Layout>
    );
  }
}

export default ConversationsContainer;
