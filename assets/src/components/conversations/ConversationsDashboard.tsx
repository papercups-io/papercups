import React from 'react';
import {Box} from 'theme-ui';
import qs from 'query-string';
import {colors, Layout, notification, Sider, Title} from '../common';
import {sleep} from '../../utils';
import {Account, Message} from '../../types';
import ConversationsPreviewList from './ConversationsPreviewList';
import ConversationContainer from './ConversationContainer';

type Props = {
  title?: string;
  account: Account | null;
  loading: boolean;
  conversationIds: Array<string>;
  messagesByConversation: {[key: string]: Array<Message>};
  fetch: () => Promise<Array<string>>;
  onSelectConversation: (id: string | null, fn?: () => void) => void;
  onUpdateConversation: (id: string, params: any) => Promise<void>;
  onDeleteConversation: (id: string) => Promise<void>;
  onSendMessage: (message: Partial<Message>, fn: () => void) => void;
};

type State = {
  loading: boolean;
  selectedConversationId: string | null;
  closing: Array<string>;
};

class ConversationsDashboard extends React.Component<Props, State> {
  scrollToEl: any = null;

  state: State = {loading: true, selectedConversationId: null, closing: []};

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
    if (!this.state.selectedConversationId) {
      return null;
    }

    const {selectedConversationId} = this.state;
    const {messagesByConversation: prevMessagesByConversation} = prev;
    const {messagesByConversation} = this.props;
    const prevMessages =
      prevMessagesByConversation[selectedConversationId] || [];
    const messages = messagesByConversation[selectedConversationId] || [];

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

    const {selectedConversationId} = this.state;

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
          selectedConversationId &&
          this.handleCloseConversation(selectedConversationId)
        );
      case 'p':
        e.preventDefault();

        return (
          selectedConversationId &&
          this.handleMarkPriority(selectedConversationId)
        );
      case 'u':
        e.preventDefault();

        return (
          selectedConversationId &&
          this.handleMarkUnpriority(selectedConversationId)
        );
      case 'o':
        e.preventDefault();

        return (
          selectedConversationId &&
          this.handleReopenConversation(selectedConversationId)
        );
      default:
        return null;
    }
  };

  getNextConversationId = () => {
    const {selectedConversationId} = this.state;
    const {conversationIds = []} = this.props;

    if (conversationIds.length === 0) {
      return null;
    }

    const lastConversationId = conversationIds[conversationIds.length - 1];

    if (!selectedConversationId) {
      return lastConversationId;
    }

    const index = conversationIds.indexOf(selectedConversationId);

    return conversationIds[index + 1] || lastConversationId || null;
  };

  getPreviousConversationId = () => {
    const {selectedConversationId} = this.state;
    const {conversationIds = []} = this.props;

    if (conversationIds.length === 0) {
      return null;
    }

    const firstConversationId = conversationIds[0];

    if (!selectedConversationId) {
      return firstConversationId;
    }

    const index = conversationIds.indexOf(selectedConversationId);

    return conversationIds[index - 1] || firstConversationId;
  };

  // TODO: make sure this works as expected
  refreshSelectedConversation = async () => {
    const {selectedConversationId} = this.state;
    const nextId = this.getNextConversationId();
    const updatedIds = await this.props.fetch();
    const hasValidSelectedId =
      selectedConversationId &&
      updatedIds.indexOf(selectedConversationId) !== -1;

    if (!hasValidSelectedId) {
      const hasValidNextId = nextId && updatedIds.indexOf(nextId) !== -1;
      const nextSelectedId = hasValidNextId ? nextId : updatedIds[0];

      this.handleSelectConversation(nextSelectedId);
    }
  };

  handleSelectConversation = (id: string | null) => {
    this.setState({selectedConversationId: id}, () => {
      this.scrollIntoView();
    });

    this.props.onSelectConversation(id);
  };

  handleCloseConversation = async (conversationId: string) => {
    this.setState({closing: [...this.state.closing, conversationId]});

    // TODO: figure out the best way to handle this when closing multiple
    // conversations in a row very quickly
    await sleep(400);
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

  handleSendMessage = (message: Partial<Message>) => {
    const {selectedConversationId: conversationId} = this.state;

    if (!conversationId) {
      return null;
    }

    this.props.onSendMessage(
      {...message, conversation_id: conversationId},
      () => {
        this.scrollIntoView();
      }
    );
  };

  render() {
    const {selectedConversationId, closing = []} = this.state;
    const {title, conversationIds = []} = this.props;
    const loading = this.props.loading || this.state.loading;
    const isClosingSelected =
      !!selectedConversationId &&
      closing.indexOf(selectedConversationId) !== -1;

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

          <ConversationsPreviewList
            loading={loading}
            selectedConversationId={selectedConversationId}
            conversationIds={conversationIds}
            isConversationClosing={(conversationId) =>
              closing.indexOf(conversationId) !== -1
            }
            onSelectConversation={this.handleSelectConversation}
          />
        </Sider>
        <Layout style={{marginLeft: 280, background: colors.white}}>
          <ConversationContainer
            loading={loading}
            selectedConversationId={selectedConversationId}
            isClosing={isClosingSelected}
            setScrollRef={(el: any) => (this.scrollToEl = el)}
            onAssignUser={this.handleAssignUser}
            onMarkPriority={this.handleMarkPriority}
            onRemovePriority={this.handleMarkUnpriority}
            onCloseConversation={this.handleCloseConversation}
            onReopenConversation={this.handleReopenConversation}
            onDeleteConversation={this.handleDeleteConversation}
            onSendMessage={this.handleSendMessage}
          />
        </Layout>
      </Layout>
    );
  }
}

export default ConversationsDashboard;
