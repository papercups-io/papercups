import React from 'react';
import {Box, Flex} from 'theme-ui';
import qs from 'query-string';
import {colors, Layout, notification, Sider, Text, Title} from '../common';
import {sleep} from '../../utils';
import {Conversation, Message, User} from '../../types';
import ConversationHeader from './ConversationHeader';
import ConversationItem from './ConversationItem';
import ConversationClosing from './ConversationClosing';
import ConversationMessages from './ConversationMessages';
import ConversationFooter from './ConversationFooter';
import ConversationDetailsSidebar from './ConversationDetailsSidebar';
import {getColorByUuid} from './support';

type Props = {
  title?: string;
  account: any;
  currentUser: User;
  currentlyOnline?: any;
  loading: boolean;
  showGetStarted: boolean;
  conversationIds: Array<string>;
  conversationsById: {[key: string]: Conversation};
  messagesByConversation: {[key: string]: Array<Message>};
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
    const q = qs.parse(window.location.search);
    const selectedConversationId = q.cid ? String(q.cid) : null;

    this.props
      .fetch()
      .then((ids) => {
        const [first] = ids;
        const selectedId = ids.find((id) => id === selectedConversationId)
          ? selectedConversationId
          : first;

        this.setState({loading: false});
        this.handleSelectConversation(selectedId);
        this.setupKeyboardShortcuts();
      })
      .then(() => this.scrollIntoView());
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
      this.scrollIntoView();
    }
  }

  setupKeyboardShortcuts = () => {
    window.addEventListener('keydown', this.handleKeyboardShortcut);
  };

  removeKeyboardShortcuts = () => {
    window.removeEventListener('keydown', this.handleKeyboardShortcut);
  };

  scrollIntoView = () => {
    this.scrollToEl && this.scrollToEl.scrollIntoView();
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
    if (!customerId) {
      return false;
    }

    const {currentlyOnline = {}} = this.props;
    const key = `customer:${customerId}`;

    return !!(currentlyOnline && currentlyOnline[key]);
  };

  handleSelectConversation = (id: string | null) => {
    this.setState({selected: id}, () => {
      this.scrollIntoView();
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
      this.scrollIntoView();
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
      !!selectedConversationId &&
      closing.indexOf(selectedConversationId) !== -1;
    const isSelectedCustomerOnline = selectedCustomer
      ? this.isCustomerOnline(selectedCustomer.id)
      : false;

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
                const color = getColorByUuid(customerId);

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
          <Flex
            sx={{
              position: 'relative',
              flex: 1,
              flexDirection: 'column',
              minHeight: 0,
              minWidth: 640,
              pr: 240, // TODO: animate this if we make it toggle-able
            }}
          >
            <ConversationMessages
              messages={messages}
              currentUser={currentUser}
              customer={selectedCustomer}
              loading={loading}
              isClosing={isClosingSelected}
              showGetStarted={showGetStarted}
              setScrollRef={(el) => (this.scrollToEl = el)}
            />

            {selectedConversation && (
              // NB: the `key` forces a rerender so the input can clear
              // any text from the last conversation and trigger autofocus
              <ConversationFooter
                key={selectedConversation.id}
                onSendMessage={this.handleSendMessage}
              />
            )}

            {selectedCustomer && selectedConversation && (
              <Box
                sx={{
                  width: 240,
                  height: '100%',
                  overflowY: 'scroll',
                  position: 'absolute',
                  right: 0,
                }}
              >
                <ConversationDetailsSidebar
                  customer={selectedCustomer}
                  isOnline={isSelectedCustomerOnline}
                  conversation={selectedConversation}
                />
              </Box>
            )}
          </Flex>
        </Layout>
      </Layout>
    );
  }
}

export default ConversationsContainer;
