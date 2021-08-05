import React from 'react';
import {Box} from 'theme-ui';
import qs from 'query-string';
import {colors, Input, Layout, notification, Sider, Title} from '../common';
import {sleep} from '../../utils';
import {ConversationsListResponse, PaginationOptions} from '../../api';
import {Account, Conversation, Message} from '../../types';
import * as API from '../../api';
import ConversationsPreviewList from './ConversationsPreviewList';
import ConversationContainer from './ConversationContainer';

type Props = {
  title?: string;
  account: Account | null;
  loading: boolean;
  conversationIds: Array<string>;
  messagesByConversation: {[key: string]: Array<Message>};
  fetcher: (query?: any) => Promise<ConversationsListResponse>;
  onRetrieveConversations: (
    conversations: Array<Conversation>
  ) => Array<string>;
  onSelectConversation: (id: string | null, fn?: () => void) => void;
  onUpdateConversation: (id: string, params: any) => Promise<void>;
  onDeleteConversation: (id: string) => Promise<void>;
  onSendMessage: (message: Partial<Message>, fn: () => void) => void;
};

type State = {
  loading: boolean;
  searching: boolean;
  query: string;
  selectedConversationId: string | null;
  conversationSearchResults: Array<string>;
  pagination: PaginationOptions;
  closing: Array<string>;
};

class ConversationsDashboard extends React.Component<Props, State> {
  scrollToEl: any = null;

  state: State = {
    loading: true,
    searching: false,
    query: '',
    selectedConversationId: null,
    conversationSearchResults: [],
    pagination: {},
    closing: [],
  };

  componentDidMount() {
    const q = qs.parse(window.location.search);
    const selectedConversationId = q.cid ? String(q.cid) : null;
    const {fetcher, onRetrieveConversations} = this.props;
    // Since the selected conversation might not exist in the paginated results,
    // we fetch it separately to guarantee that it will be displayed
    const selectedConversationPromise = selectedConversationId
      ? API.fetchConversation(selectedConversationId)
      : Promise.resolve(null);

    Promise.all([fetcher(), selectedConversationPromise]).then(
      ([result, selectedConversation]) => {
        const {data = [], ...pagination} = result;
        const conversations = selectedConversation
          ? [selectedConversation, ...data]
          : data;
        const ids = onRetrieveConversations(conversations);
        const [first] = ids;
        const selectedId = ids.find((id) => id === selectedConversationId)
          ? selectedConversationId
          : first;

        this.setState({pagination, loading: false});
        this.handleSelectConversation(selectedId);
        this.setupKeyboardShortcuts();
      }
    );
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

  getConversationIds = () => {
    const {conversationIds = []} = this.props;
    const {query, conversationSearchResults = []} = this.state;
    const hasValidQuery = query && query.trim().length > 0;

    if (
      hasValidQuery &&
      conversationSearchResults &&
      conversationSearchResults.length > 0
    ) {
      return conversationSearchResults;
    } else {
      return conversationIds;
    }
  };

  setupKeyboardShortcuts = () => {
    window.addEventListener('keydown', this.handleKeyboardShortcut);
  };

  removeKeyboardShortcuts = () => {
    window.removeEventListener('keydown', this.handleKeyboardShortcut);
  };

  scrollIntoView = () => {
    this.scrollToEl && this.scrollToEl.scrollIntoView();
  };

  handleLoadMoreConversations = async (): Promise<void> => {
    const {query, pagination = {}, conversationSearchResults = []} = this.state;
    const {fetcher, onRetrieveConversations} = this.props;
    const hasValidQuery = query && query.trim().length > 0;
    const filters = hasValidQuery ? {q: query} : {};

    const {data: conversations = [], ...next} = await fetcher({
      after: pagination.next,
      ...filters,
    });

    if (hasValidQuery) {
      const ids = onRetrieveConversations(conversations);

      this.setState({
        pagination: next,
        loading: false,
        conversationSearchResults: [...conversationSearchResults, ...ids],
      });
    } else {
      this.setState({pagination: next, loading: false}, () =>
        onRetrieveConversations(conversations)
      );
    }
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
    const conversationIds = this.getConversationIds();

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
    const conversationIds = this.getConversationIds();

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
    const {query} = this.state;
    const nextId = this.getNextConversationId();
    const filters = query && query.trim().length ? {q: query} : {};
    const {data: conversations} = await this.props.fetcher(filters);

    this.props.onRetrieveConversations(conversations);

    const conversationIds = this.getConversationIds();
    const {selectedConversationId} = this.state;
    const hasValidSelectedId =
      selectedConversationId &&
      conversationIds.indexOf(selectedConversationId) !== -1;

    if (!hasValidSelectedId) {
      const hasValidNextId = nextId && conversationIds.indexOf(nextId) !== -1;
      const nextSelectedId = hasValidNextId ? nextId : conversationIds[0];

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

  handleAssignUser = (conversationId: string, userId: string | null) => {
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

  handleSearchConversations = async (q: string) => {
    this.setState({query: q, searching: true});

    const {fetcher, onRetrieveConversations} = this.props;
    const hasValidQuery = q && q.trim().length;
    const filters = hasValidQuery ? {q} : {};
    const {data: conversations = [], ...pagination} = await fetcher(filters);
    const ids = onRetrieveConversations(conversations);

    this.setState({
      pagination,
      conversationSearchResults: hasValidQuery ? ids : [],
      loading: false,
      searching: false,
    });

    if (q && q.trim().length > 0 && ids.length === 0) {
      notification.open({
        message: `No results found for "${q}"`,
        duration: 4, // 4 seconds
        description: <Box>Please try another query</Box>,
      });
    }
  };

  render() {
    const {
      selectedConversationId,
      searching,
      pagination = {},
      closing = [],
    } = this.state;
    const {title} = this.props;
    const conversationIds = this.getConversationIds();
    const loading = this.props.loading || this.state.loading;
    const hasMoreConversations =
      !!pagination.next &&
      !!pagination.total &&
      conversationIds.length < pagination.total;
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
          <Box sx={{borderBottom: '1px solid #f0f0f0'}}>
            <Box px={3} pt={3}>
              <Title level={3} style={{marginBottom: 0, marginTop: 8}}>
                {title || 'Conversations'}
              </Title>
            </Box>

            <Box mt={3} px="1px">
              <Input.Search
                className="ConversationsSearchInput"
                placeholder="Search messages..."
                disabled={loading || searching}
                loading={searching}
                allowClear
                addonAfter={null}
                onSearch={this.handleSearchConversations}
              />
            </Box>
          </Box>

          <ConversationsPreviewList
            loading={loading}
            selectedConversationId={selectedConversationId}
            conversationIds={conversationIds}
            hasMoreConversations={hasMoreConversations}
            isConversationClosing={(conversationId) =>
              closing.indexOf(conversationId) !== -1
            }
            onSelectConversation={this.handleSelectConversation}
            onLoadMoreConversations={this.handleLoadMoreConversations}
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
