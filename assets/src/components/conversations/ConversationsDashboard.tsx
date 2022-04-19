import React from 'react';
import {Link, RouteComponentProps} from 'react-router-dom';
import {Box, Flex} from 'theme-ui';

import * as API from '../../api';
import {Account, Conversation, Inbox, Message, User} from '../../types';
import {
  colors,
  Button,
  Input,
  Layout,
  notification,
  Result,
  Sider,
  Title,
  Tooltip,
} from '../common';
import {SettingOutlined} from '../icons';
import {
  CONVERSATIONS_DASHBOARD_SIDER_WIDTH,
  formatServerError,
  isWindowHidden,
  noop,
  sleep,
} from '../../utils';
import ConversationsPreviewList from './ConversationsPreviewList';
import SelectedConversationContainer from './SelectedConversationContainer';
import ConversationHeader from './ConversationHeader';
import {useConversations} from './ConversationsProvider';
import {
  getNextConversationId,
  getPreviousConversationId,
  getNextSelectedConversationId,
  isUnreadConversation,
  throttledNotificationSound,
} from './support';
import {useNotifications} from './NotificationsProvider';
import {useAuth} from '../auth/AuthProvider';

const defaultConversationFilter = () => true;

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

const GettingStartedRedirect = ({inbox}: {inbox?: Inbox | null}) => {
  const extra =
    inbox && inbox.id ? (
      <Link to={`/inboxes/${inbox.id}`}>
        <Button type="primary">Configure inbox</Button>
      </Link>
    ) : (
      <Link to="/getting-started">
        <Button type="primary">Get started</Button>
      </Link>
    );

  return (
    <Box my={4}>
      <Result
        title="No messages"
        subTitle="It looks like no channels have been set up yet!"
        extra={extra}
      />
    </Box>
  );
};

const EmptyState = ({
  loading,
  isNewUser,
  inbox,
}: {
  loading?: boolean;
  isNewUser?: boolean;
  inbox?: Inbox | null;
}) => {
  if (loading) {
    return null;
  }

  if (isNewUser) {
    return <GettingStartedRedirect inbox={inbox} />;
  } else {
    return <EmptyMessagesPlaceholder />;
  }
};

export const ConversationsDashboard = ({
  title,
  account,
  currentUser,
  initialSelectedConversationId,
  inbox,
  filter = {},
  onSelectConversation = noop,
  isValidConversation = defaultConversationFilter,
}: {
  title: string;
  account: Account;
  currentUser: User;
  initialSelectedConversationId: string | null;
  inbox?: Inbox | null;
  filter: Record<string, any>;
  onSelectConversation: (conversationId: string) => void;
  isValidConversation: (conversation: Conversation) => boolean;
}) => {
  const scrollToEl = React.useRef<any>(null);
  const [status, setStatus] = React.useState<
    'loading' | 'searching' | 'success' | 'error'
  >('loading');
  const [error, setErrorMessage] = React.useState<string | null>(null);
  const [isNewUser, setNewUser] = React.useState<boolean>(false);
  // TODO: can we rely on these, or should we use the cached ids in ConversationsProvider?
  const [conversationIds, setConversationIds] = React.useState<Array<string>>(
    []
  );
  const [pagination, setPaginationOptions] = React.useState<
    API.PaginationOptions
  >({});
  const [selectedConversationId, setSelectedConversationId] = React.useState<
    string | null
  >(initialSelectedConversationId);
  const [closing, setClosingConversations] = React.useState<Array<string>>([]);

  const {
    fetchConversations,
    fetchConversationById,
    getValidConversationsByIds,
    getConversationById,
    getMessagesByConversationId,
    updateConversationById,
    archiveConversationById,
  } = useConversations();

  const {
    channel,

    handleConversationSeen,
    onNewMessage,
    onNewConversation,
  } = useNotifications();

  // TODO: are these necessary? Still unclear on React.useCallback usage
  const onMessageCreated = React.useCallback(onNewMessage, [
    selectedConversationId,
  ]);
  const onConversationCreated = React.useCallback(onNewConversation, [
    conversationIds.length,
  ]);

  React.useEffect(() => {
    if (!channel) {
      return;
    }

    const subscriptions = [
      onMessageCreated(handleNewMessage),
      onConversationCreated(handleNewConversation),
    ];

    return () => {
      subscriptions.forEach((unsubscribe) => unsubscribe());
    };
    // eslint-disable-next-line
  }, [
    channel,
    selectedConversationId,
    conversationIds.length,
    onMessageCreated,
    onConversationCreated,
  ]);

  const {users = []} = account;
  // TODO: is there a more efficient way to do this?
  const conversations = getValidConversationsByIds(
    conversationIds,
    isValidConversation
  );
  const hasMoreConversations =
    !!pagination.next &&
    !!pagination.total &&
    conversations.length < pagination.total;
  const isClosingSelected =
    !!selectedConversationId && closing.indexOf(selectedConversationId) !== -1;
  const conversation = getConversationById(selectedConversationId);
  const messages = getMessagesByConversationId(selectedConversationId);

  React.useEffect(() => {
    setStatus('loading');

    Promise.all([
      fetchFilteredConversations(),
      fetchInitialConversation(),
      checkForNewUser(),
    ])
      .then(([result, initialSelectedConversation, shouldMarkNewUser]) => {
        const {data: conversations, ...pagination} = result;
        // TODO: clean this up
        const conversationIds = [
          ...new Set(
            [initialSelectedConversation, ...conversations]
              .filter(
                (conversation): conversation is Conversation => !!conversation
              )
              .map((c) => c.id)
          ),
        ];
        const [first] = conversationIds;
        const selected = initialSelectedConversation?.id ?? first;
        // TODO: should we handle conversation IDs and pagination options here,
        // or in the ConversationsProvider? (Might need to keep pagination here)
        setConversationIds(conversationIds);
        setPaginationOptions(pagination);
        handleSelectConversation(selected || null);
        setNewUser(shouldMarkNewUser);
      })
      .then(() => setStatus('success'))
      .catch((error) => {
        setStatus('error');
        setErrorMessage(formatServerError(error));
      });

    // FIXME?
    // eslint-disable-next-line
  }, [title]);

  // TODO: refactor into its own hook?
  const handleKeyDown = React.useCallback(handleKeyboardShortcuts, [
    selectedConversationId,
    conversations.length,
  ]);

  React.useEffect(() => {
    window.addEventListener('keydown', handleKeyDown);

    return () => window.removeEventListener('keydown', handleKeyDown);
  }, [handleKeyDown]);

  React.useEffect(() => {
    scrollToEl.current?.scrollIntoView();
  }, [title, selectedConversationId, messages.length]);

  function setScrollRef(el: any) {
    scrollToEl.current = el || null;
    scrollToEl.current?.scrollIntoView();
  }

  async function checkForNewUser() {
    const filters = inbox && inbox.id ? {inbox_id: inbox.id} : {};
    const {count = 0} = await API.countAllConversations(filters);

    return count === 0;
  }

  async function fetchDefaultConversations() {
    setStatus('loading');

    return fetchFilteredConversations()
      .then((result) => {
        const {data: conversations, ...pagination} = result;
        const conversationIds = [...new Set(conversations.map((c) => c.id))];
        const [first] = conversationIds;
        // TODO: should we handle conversation IDs and pagination options here,
        // or in the ConversationsProvider? (Might need to keep pagination here)
        setConversationIds(conversationIds);
        setPaginationOptions(pagination);
        handleSelectConversation(first || null);
      })
      .then(() => setStatus('success'))
      .catch((error) => {
        setStatus('error');
        setErrorMessage(formatServerError(error));
      });
  }

  function handleNewMessage(message: Message) {
    const {conversation_id: conversationId} = message;

    if (isWindowHidden(document || window.document)) {
      throttledNotificationSound();
    } else if (selectedConversationId === conversationId) {
      handleConversationSeen(conversationId);
    }
  }

  function handleNewConversation(conversationId: string) {
    setConversationIds([conversationId, ...conversationIds]);
  }

  function fetchInitialConversation() {
    if (!initialSelectedConversationId) {
      return null;
    }

    return fetchConversationById(initialSelectedConversationId);
  }

  function handleKeyboardShortcuts(e: KeyboardEvent) {
    // TODO: should we use something other than metaKey/cmd?
    const {metaKey, key} = e;

    if (!metaKey) {
      return null;
    }

    const validConversationIds = conversations.map((c) => c.id);

    // TODO: clean up a bit
    switch (key) {
      case 'ArrowDown':
        e.preventDefault();

        return handleSelectConversation(
          getNextConversationId(selectedConversationId, validConversationIds)
        );
      case 'ArrowUp':
        e.preventDefault();

        return handleSelectConversation(
          getPreviousConversationId(
            selectedConversationId,
            validConversationIds
          )
        );
      case 'd':
        e.preventDefault();

        return (
          selectedConversationId &&
          handleCloseConversation(selectedConversationId)
        );
      case 'p':
        e.preventDefault();

        return (
          selectedConversationId && handleMarkPriority(selectedConversationId)
        );
      case 'u':
        e.preventDefault();

        return (
          selectedConversationId && handleRemovePriority(selectedConversationId)
        );
      case 'o':
        e.preventDefault();

        return (
          selectedConversationId &&
          handleReopenConversation(selectedConversationId)
        );
      default:
        return null;
    }
  }

  function fetchFilteredConversations(params = {}) {
    return fetchConversations({...filter, ...params});
  }

  function handleSelectConversation(conversationId: string | null) {
    setSelectedConversationId(conversationId);

    if (!conversationId) {
      return;
    }

    const selected = getConversationById(conversationId);

    if (selected && isUnreadConversation(selected, currentUser)) {
      handleConversationSeen(conversationId);
    }

    onSelectConversation(conversationId);
  }

  async function handleLoadMoreConversations() {
    const {
      data = [],
      ...nextPaginationOptions
    } = await fetchFilteredConversations({
      after: pagination.next,
    });

    setConversationIds([
      ...new Set([...conversationIds, ...data.map((c) => c.id)]),
    ]);
    setPaginationOptions(nextPaginationOptions);
  }

  async function handleAssignUser(
    conversationId: string,
    userId: string | null
  ) {
    await updateConversationById(conversationId, {assignee_id: userId});
  }

  async function handleMarkPriority(conversationId: string) {
    await updateConversationById(conversationId, {
      priority: 'priority',
    });
  }

  async function handleRemovePriority(conversationId: string) {
    await updateConversationById(conversationId, {
      priority: 'not_priority',
    });
  }

  async function handleCloseConversation(conversationId: string) {
    const conversation = getConversationById(conversationId);

    if (!conversation || conversation.status === 'closed') {
      return;
    }

    setClosingConversations([...closing, conversationId]);

    const validConversationIds = conversations.map((c) => c.id);
    const nextSelectedConversationId = getNextSelectedConversationId(
      selectedConversationId,
      validConversationIds
    );

    // Optimistic update
    handleSelectConversation(nextSelectedConversationId);

    // TODO: figure out the best way to handle this when closing multiple
    // conversations in a row very quickly
    await sleep(400);
    await updateConversationById(conversationId, {status: 'closed'});

    setConversationIds(validConversationIds);
    setClosingConversations(closing.filter((id) => id !== conversationId));
  }

  async function handleReopenConversation(conversationId: string) {
    const conversation = getConversationById(conversationId);

    if (!conversation || conversation.status === 'open') {
      return;
    }

    const validConversationIds = conversations.map((c) => c.id);
    const nextSelectedConversationId = getNextSelectedConversationId(
      selectedConversationId,
      validConversationIds
    );

    // Optimistic update
    handleSelectConversation(nextSelectedConversationId);
    setConversationIds(validConversationIds);

    await updateConversationById(conversationId, {status: 'open'});

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
  }

  async function handleDeleteConversation(conversationId: string) {
    const validConversationIds = conversations.map((c) => c.id);
    const nextSelectedConversationId = getNextSelectedConversationId(
      selectedConversationId,
      validConversationIds
    );

    await archiveConversationById(conversationId);

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

    handleSelectConversation(nextSelectedConversationId);
    setConversationIds(validConversationIds);
  }

  // TODO: test this out more!
  async function handleSearchConversations(query: string) {
    if (!query || !query.trim().length) {
      return await fetchDefaultConversations();
    }

    setStatus('searching');

    const {data = [], ...pagination} = await fetchFilteredConversations({
      q: query,
    });
    const conversationIds = [...new Set(data.map((c) => c.id))];
    const [first] = conversationIds;

    setConversationIds(conversationIds);
    setPaginationOptions(pagination);
    handleSelectConversation(first || null);

    setStatus('success');
  }

  if (error) {
    return (
      <Flex
        sx={{
          flex: 1,
          justifyContent: 'center',
          alignItems: 'center',
          height: '100%',
        }}
      >
        <Result
          status="error"
          title="Error retrieving inbox"
          subTitle={error || 'Unknown error'}
        />
      </Flex>
    );
  }

  return (
    <Layout style={{background: colors.white}}>
      <Sider
        theme="light"
        width={CONVERSATIONS_DASHBOARD_SIDER_WIDTH}
        style={{
          borderRight: '1px solid #f0f0f0',
          overflow: 'auto',
          height: '100vh',
          position: 'fixed',
        }}
      >
        <Box sx={{position: 'relative', borderBottom: '1px solid #f0f0f0'}}>
          {!!inbox?.id && (
            <Box sx={{position: 'absolute', top: '6px', right: '6px'}}>
              <Tooltip title="Configure inbox">
                <Link to={`/inboxes/${inbox.id}`}>
                  <Button
                    className="Button--faded"
                    type="text"
                    size="small"
                    shape="circle"
                    icon={<SettingOutlined />}
                  />
                </Link>
              </Tooltip>
            </Box>
          )}
          <Box px={3} py={3}>
            <Title level={3} style={{marginBottom: 0, marginTop: 8}}>
              {title}
            </Title>
          </Box>
          <Box px="1px">
            <Input.Search
              className="ConversationsSearchInput"
              placeholder="Search messages..."
              disabled={status === 'loading'}
              loading={status === 'searching'}
              allowClear
              addonAfter={null}
              onSearch={handleSearchConversations}
            />
          </Box>
        </Box>

        <ConversationsPreviewList
          loading={status === 'loading'}
          conversations={conversations}
          selectedConversationId={selectedConversationId}
          hasMoreConversations={hasMoreConversations}
          isConversationClosing={(conversationId) =>
            closing.indexOf(conversationId) !== -1
          }
          onSelectConversation={handleSelectConversation}
          onLoadMoreConversations={handleLoadMoreConversations}
        />
      </Sider>

      <Layout
        style={{
          marginLeft: CONVERSATIONS_DASHBOARD_SIDER_WIDTH,
          background: colors.white,
        }}
      >
        {conversation && (
          <ConversationHeader
            conversation={conversation}
            users={users}
            onAssignUser={handleAssignUser}
            onMarkPriority={handleMarkPriority}
            onRemovePriority={handleRemovePriority}
            onCloseConversation={handleCloseConversation}
            onReopenConversation={handleReopenConversation}
            onDeleteConversation={handleDeleteConversation}
          />
        )}
        {/* TODO: if no selected conversation, render something else */}
        {conversation ? (
          <SelectedConversationContainer
            loading={status === 'loading'}
            account={account}
            currentUser={currentUser}
            conversation={conversation}
            isClosing={isClosingSelected}
            setScrollRef={setScrollRef}
          />
        ) : (
          <EmptyState
            loading={status === 'loading'}
            isNewUser={isNewUser}
            inbox={inbox}
          />
        )}
      </Layout>
    </Layout>
  );
};

type ConversationBucket =
  | 'all'
  | 'me'
  | 'mentions'
  | 'unread'
  | 'unassigned'
  | 'priority'
  | 'closed';

type BucketMapping = {
  title: string;
  filter: Record<string, any>;
  isValidConversation: (conversation: Conversation) => boolean;
};

const isValidBucket = (bucket: string): bucket is ConversationBucket => {
  switch (bucket) {
    case 'all':
    case 'me':
    case 'mentions':
    case 'unread':
    case 'unassigned':
    case 'priority':
    case 'closed':
      return true;
    default:
      return false;
  }
};

const Wrapper = (
  props: RouteComponentProps<{bucket: string; conversation_id?: string}>
) => {
  const {bucket, conversation_id: conversationId = null} = props.match.params;
  const {currentUser, account} = useAuth();

  if (!isValidBucket(bucket)) {
    // TODO: render error or redirect to default
    return null;
  }

  if (!account || !currentUser) {
    return null;
  }

  const getBucketConfig = (bucket: ConversationBucket): BucketMapping => {
    switch (bucket) {
      case 'all':
        return {
          title: 'All conversations',
          filter: {status: 'open'},
          isValidConversation: (conversation) => {
            const {status, archived_at, closed_at} = conversation;

            return status === 'open' && !archived_at && !closed_at;
          },
        };
      case 'me':
        return {
          title: 'Assigned to me',
          filter: {status: 'open', assignee_id: 'me'},
          isValidConversation: (conversation) => {
            const {status, archived_at, closed_at, assignee_id} = conversation;

            return (
              assignee_id === currentUser.id &&
              status === 'open' &&
              !archived_at &&
              !closed_at
            );
          },
        };
      case 'mentions':
        return {
          title: 'Mentions',
          filter: {status: 'open', mentioning: 'me'},
          isValidConversation: (conversation) => {
            const {
              status,
              archived_at,
              closed_at,
              mentions = [],
            } = conversation;
            const isMentioned = mentions.some((mention) => {
              return mention.user_id === currentUser.id;
            });

            return (
              isMentioned && status === 'open' && !archived_at && !closed_at
            );
          },
        };
      case 'unread':
        return {
          title: 'All unread',
          filter: {status: 'open', read: false},
          isValidConversation: (conversation) => {
            const {status, archived_at, closed_at} = conversation;

            return status === 'open' && !archived_at && !closed_at;
          },
        };
      case 'unassigned':
        return {
          title: 'Unassigned',
          filter: {status: 'open', assignee_id: null},
          isValidConversation: (conversation) => {
            const {status, archived_at, closed_at, assignee_id} = conversation;

            return (
              !assignee_id && status === 'open' && !archived_at && !closed_at
            );
          },
        };
      case 'priority':
        return {
          title: 'Prioritized',
          filter: {status: 'open', priority: 'priority'},
          isValidConversation: (conversation) => {
            const {status, archived_at, closed_at, priority} = conversation;

            return (
              priority === 'priority' &&
              status === 'open' &&
              !archived_at &&
              !closed_at
            );
          },
        };
      case 'closed':
        return {
          title: 'Closed',
          filter: {status: 'closed'},
          isValidConversation: (conversation) => {
            const {status, archived_at} = conversation;

            return status === 'closed' && !archived_at;
          },
        };
    }
  };

  const {title, filter, isValidConversation} = getBucketConfig(bucket);

  const handleSelectConversation = (conversationId: string) =>
    props.history.push(`/conversations/${bucket}/${conversationId}`);

  return (
    <ConversationsDashboard
      title={title}
      account={account}
      currentUser={currentUser}
      filter={filter}
      initialSelectedConversationId={conversationId}
      onSelectConversation={handleSelectConversation}
      isValidConversation={isValidConversation}
    />
  );
};

export default Wrapper;
