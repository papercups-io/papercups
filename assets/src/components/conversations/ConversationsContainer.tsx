import React from 'react';
import {Link} from 'react-router-dom';
import {Box, Flex} from 'theme-ui';
import {
  Button,
  colors,
  Content,
  Layout,
  notification,
  Result,
  Sider,
  Text,
  Title,
} from '../common';
import {SmileOutlined} from '../icons';
import {sleep} from '../../utils';
import Spinner from '../Spinner';
import ChatMessage from './ChatMessage';
import ConversationHeader from './ConversationHeader';
import ConversationItem from './ConversationItem';
import ConversationClosing from './ConversationClosing';
import ConversationFooter from './ConversationFooter';

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
  currentlyOnline?: any;
  loading: boolean;
  showGetStarted: boolean;
  conversationIds: Array<string>;
  conversationsById: {[key: string]: any};
  messagesByConversation: {[key: string]: any};
  fetch: () => Promise<Array<string>>;
  onSelectConversation: (id: string | null, fn?: () => void) => void;
  onUpdateConversation: (id: string, params: any) => Promise<void>;
  onDeleteConversation: (id: string) => Promise<void>;
  onSendMessage: (
    message: string,
    conversationId: string,
    fn: () => void
  ) => void;
};

type State = {
  loading: boolean;
  selected: string | null;
  closing: Array<string>;
};

class ConversationsContainer extends React.Component<Props, State> {
  scrollToEl: any = null;

  state: State = {loading: true, selected: null, closing: []};

  componentDidMount() {
    this.props
      .fetch()
      .then(([first]) => {
        this.setState({loading: false});
        this.handleSelectConversation(first);
        this.setupKeyboardShortcuts();
      })
      .then(() => this.scrollToEl.scrollIntoView());
  }

  componentWillUnmount() {
    // Mark selected conversation as null
    this.handleSelectConversation(null);
    this.removeKeyboardShortcuts();
  }

  componentDidUpdate(prev: Props) {
    if (!this.state.selected) {
      return null;
    }

    const {selected} = this.state;
    const {messagesByConversation: prevMessagesByConversation} = prev;
    const {messagesByConversation} = this.props;
    const prevMessages = prevMessagesByConversation[selected] || [];
    const messages = messagesByConversation[selected] || [];

    if (messages.length > prevMessages.length) {
      this.scrollToEl.scrollIntoView();
    }
  }

  setupKeyboardShortcuts = () => {
    window.addEventListener('keydown', this.handleKeyboardShortcut);
  };

  removeKeyboardShortcuts = () => {
    window.removeEventListener('keydown', this.handleKeyboardShortcut);
  };

  handleKeyboardShortcut = (e: any) => {
    // TODO: should we use something other than metaKey/cmd?
    const {metaKey, key} = e;

    if (!metaKey) {
      return null;
    }

    // TODO: clean up a bit
    switch (key) {
      case 'ArrowDown':
        e.preventDefault();

        return this.handleSelectConversation(this.getNextConversationId());
      case 'ArrowUp':
        e.preventDefault();

        return this.handleSelectConversation(this.getPreviousConversationId());
      case 'd':
        e.preventDefault();

        return (
          this.state.selected &&
          this.handleCloseConversation(this.state.selected)
        );
      case 'p':
        e.preventDefault();

        return (
          this.state.selected && this.handleMarkPriority(this.state.selected)
        );
      case 'u':
        e.preventDefault();

        return (
          this.state.selected && this.handleMarkUnpriority(this.state.selected)
        );
      case 'o':
        e.preventDefault();

        return (
          this.state.selected &&
          this.handleReopenConversation(this.state.selected)
        );
      default:
        return null;
    }
  };

  getNextConversationId = () => {
    const {selected} = this.state;
    const {conversationIds = []} = this.props;

    if (conversationIds.length === 0) {
      return null;
    }

    const lastConversationId = conversationIds[conversationIds.length - 1];

    if (!selected) {
      return lastConversationId;
    }

    const index = conversationIds.indexOf(selected);

    return conversationIds[index + 1] || lastConversationId || null;
  };

  getPreviousConversationId = () => {
    const {selected} = this.state;
    const {conversationIds = []} = this.props;

    if (conversationIds.length === 0) {
      return null;
    }

    const firstConversationId = conversationIds[0];

    if (!selected) {
      return firstConversationId;
    }

    const index = conversationIds.indexOf(selected);

    return conversationIds[index - 1] || firstConversationId;
  };

  // TODO: make sure this works as expected
  refreshSelectedConversation = async () => {
    const {selected} = this.state;
    const nextId = this.getNextConversationId();
    const updatedIds = await this.props.fetch();
    const hasValidSelectedId = selected && updatedIds.indexOf(selected) !== -1;

    if (!hasValidSelectedId) {
      const hasValidNextId = nextId && updatedIds.indexOf(nextId) !== -1;
      const nextSelectedId = hasValidNextId ? nextId : updatedIds[0];

      this.handleSelectConversation(nextSelectedId);
    }
  };

  isCustomerOnline = (customerId: string) => {
    const {currentlyOnline = {}} = this.props;
    const key = `customer:${customerId}`;

    return !!(currentlyOnline && currentlyOnline[key]);
  };

  handleSelectConversation = (id: string | null) => {
    this.setState({selected: id}, () => {
      this.scrollToEl.scrollIntoView();
    });

    this.props.onSelectConversation(id);
  };

  handleCloseConversation = async (conversationId: string) => {
    this.setState({closing: [...this.state.closing, conversationId]});

    // TODO: figure out the best way to handle this when closing multiple
    // conversations in a row very quickly
    await sleep(1000);
    await this.props.onUpdateConversation(conversationId, {status: 'closed'});
    await this.refreshSelectedConversation();

    this.setState({
      closing: this.state.closing.filter((id) => id !== conversationId),
    });
  };

  handleReopenConversation = async (conversationId: string) => {
    await this.props.onUpdateConversation(conversationId, {status: 'open'});

    notification.open({
      message: 'Conversation re-opened!',
      duration: 2, // 2 seconds
      description: (
        <Box>
          You can view this conversations once again{' '}
          <a href="/conversations/all">here</a>.
        </Box>
      ),
    });

    await sleep(400);
    await this.refreshSelectedConversation();
  };

  handleDeleteConversation = async (conversationId: string) => {
    await this.props.onDeleteConversation(conversationId);

    notification.open({
      message: 'Conversation deleted!',
      duration: 2, // 2 seconds
      description: (
        <Box>
          This conversation was permanently deleted. You can view your active
          conversations <a href="/conversations/all">here</a>.
        </Box>
      ),
    });

    await sleep(400);
    await this.refreshSelectedConversation();
  };

  handleMarkPriority = async (conversationId: string) => {
    await this.props.onUpdateConversation(conversationId, {
      priority: 'priority',
    });
    await this.refreshSelectedConversation();
  };

  handleMarkUnpriority = async (conversationId: string) => {
    await this.props.onUpdateConversation(conversationId, {
      priority: 'not_priority',
    });
    await this.refreshSelectedConversation();
  };

  handleAssignUser = (conversationId: string, userId: string) => {
    this.props.onUpdateConversation(conversationId, {assignee_id: userId});
  };

  handleSendMessage = (message: string) => {
    const {selected: conversationId} = this.state;

    if (!conversationId) {
      return null;
    }

    this.props.onSendMessage(message, conversationId, () => {
      this.scrollToEl.scrollIntoView();
    });
  };

  render() {
    const {selected: selectedConversationId, closing = []} = this.state;
    const {
      title,
      account,
      currentUser,
      showGetStarted,
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
    const selectedCustomer = selectedConversation
      ? selectedConversation.customer
      : null;

    const loading = this.props.loading || this.state.loading;
    const isClosingSelected =
      selectedConversationId && closing.indexOf(selectedConversationId) !== -1;

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
            {!loading && conversationIds.length ? (
              conversationIds.map((conversationId, idx) => {
                const conversation = conversationsById[conversationId];
                const messages = messagesByConversation[conversationId];
                const {customer_id: customerId} = conversation;
                const isCustomerOnline = this.isCustomerOnline(customerId);
                const isHighlighted = conversationId === selectedConversationId;
                const isClosing = closing.indexOf(conversationId) !== -1;
                const {gold, red, green, purple, magenta} = colors;
                // TODO: come up with a better way to make colors/avatars consistent
                const colorIndex = parseInt(customerId, 32) % 5;
                const color = [gold, red, green, purple, magenta][colorIndex];

                if (isClosing) {
                  return (
                    <ConversationClosing
                      key={conversationId}
                      isHighlighted={isHighlighted}
                    />
                  );
                }

                return (
                  <ConversationItem
                    key={conversationId}
                    conversation={conversation}
                    messages={messages}
                    isHighlighted={isHighlighted}
                    isCustomerOnline={isCustomerOnline}
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
            onDeleteConversation={this.handleDeleteConversation}
          />

          <Content
            style={{overflowY: 'scroll', opacity: isClosingSelected ? 0.6 : 1}}
          >
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
                  messages.map((msg: any, key: number) => {
                    // Slight hack
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
                        customer={selectedCustomer}
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
            // NB: the `key` forces a rerender so the input can clear
            // any text from the last conversation and trigger autofocus
            <ConversationFooter
              key={selectedConversation.id}
              onSendMessage={this.handleSendMessage}
            />
          )}
        </Layout>
      </Layout>
    );
  }
}

export default ConversationsContainer;
