import React from 'react';
import {RouteComponentProps} from 'react-router';
import {Box, Flex} from 'theme-ui';

import * as API from '../../api';
import {Account, Conversation, Message, User} from '../../types';
import {colors, Layout, notification, Result, Sider, Title} from '../common';
import {
  CONVERSATIONS_DASHBOARD_OFFSET,
  CONVERSATIONS_DASHBOARD_SIDER_OFFSET,
  CONVERSATIONS_DASHBOARD_SIDER_WIDTH,
  formatServerError,
  isWindowHidden,
  sleep,
} from '../../utils';
import ConversationsPreviewList from './ConversationsPreviewList';
import SelectedConversationContainer from './SelectedConversationContainer';
import ConversationHeader from './ConversationHeader';
import {useConversations} from './ConversationsProvider';
import {isUnreadConversation, throttledNotificationSound} from './support';
import {useNotifications} from './NotificationsProvider';
import {useAuth} from '../auth/AuthProvider';

const defaultConversationFilter = () => true;

const getNextSelectedConversationId = (
  selectedConversationId: string | null,
  validConversationIds: Array<string>
) => {
  if (!validConversationIds || !validConversationIds.length) {
    return null;
  }

  const [first] = validConversationIds;

  if (!selectedConversationId) {
    return first;
  }

  const index = validConversationIds.indexOf(selectedConversationId);

  if (index === -1) {
    return first;
  }

  const min = 0;
  const max = validConversationIds.length - 1;
  const next = validConversationIds[Math.min(index + 1, max)];
  const previous = validConversationIds[Math.max(index - 1, min)];

  if (index === min) {
    return next;
  } else if (index === max) {
    return previous;
  } else {
    const [selected = null] = [next, previous, first].filter(
      (opt) => !!opt && opt !== selectedConversationId
    );

    return selected;
  }
};

// TODO: DRY up with InboxConversations component
export const ConversationsDashboard = ({
  title,
  account,
  currentUser,
  filter = {},
  isValidConversation = defaultConversationFilter,
}: {
  title: string;
  account: Account;
  currentUser: User;
  filter: Record<string, any>;
  isValidConversation: (conversation: Conversation) => boolean;
}) => {
  const scrollToEl = React.useRef<any>(null);
  const [status, setStatus] = React.useState<'loading' | 'success' | 'error'>(
    'loading'
  );
  const [error, setErrorMessage] = React.useState<string | null>(null);
  // TODO: maybe we don't even need to track these here?
  const [conversationIds, setConversationIds] = React.useState<Array<string>>(
    []
  );
  const [pagination, setPaginationOptions] = React.useState<
    API.PaginationOptions
  >({});
  const [selectedConversationId, setSelectedConversationId] = React.useState<
    string | null
  >(null);
  const [closing, setClosingConversations] = React.useState<Array<string>>([]);

  const {
    fetchConversations,
    getValidConversations,
    getConversationById,
    getMessagesByConversationId,
    updateConversationById,
    archiveConversationById,
  } = useConversations();

  const {
    channel,
    handleSendMessage,
    handleConversationSeen,
    onNewMessage,
    onNewConversation,
  } = useNotifications();

  // TODO: are these necessary? Still unclear on React.useCallback usage
  const onMessageCreated = React.useCallback(onNewMessage, [
    selectedConversationId,
  ]);
  const onConversationCreated = React.useCallback(onNewConversation, []);

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
    onMessageCreated,
    onConversationCreated,
  ]);

  function handleNewMessage(message: Message) {
    const {conversation_id: conversationId} = message;

    if (isWindowHidden(document || window.document)) {
      console.log('Playing notification sound!', message);
      throttledNotificationSound();
    } else if (selectedConversationId === conversationId) {
      console.log('Marking as seen!', message);
      handleConversationSeen(conversationId);
    }
  }

  function handleNewConversation(conversationId: string) {
    // TODO: is there anything we need to do on new conversation events?
  }

  const {users = []} = account;
  // TODO: is there a more efficient way to do this?
  const conversations = getValidConversations(isValidConversation);
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

    fetchFilteredConversations()
      .then((result) => {
        const {data: conversations, ...pagination} = result;
        const conversationIds = conversations.map((c) => c.id);
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

    // FIXME?
    // eslint-disable-next-line
  }, [title]);

  React.useEffect(() => {
    scrollToEl.current?.scrollIntoView();
  }, [title, selectedConversationId, messages.length]);

  function setScrollRef(el: any) {
    scrollToEl.current = el || null;
    scrollToEl.current?.scrollIntoView();
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

    // TODO: history.push(/inboxes/:inbox_id/conversations/:conversation_id)
  }

  async function handleLoadMoreConversations() {
    const {data = [], ...nextPaginationOptions} = await fetchConversations({
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
    setClosingConversations([...closing, conversationId]);

    const validConversationIds = conversations.map((c) => c.id);
    const nextSelectedConversationId = getNextSelectedConversationId(
      selectedConversationId,
      validConversationIds
    );

    // TODO: figure out the best way to handle this when closing multiple
    // conversations in a row very quickly
    await sleep(400);
    await updateConversationById(conversationId, {status: 'closed'});

    handleSelectConversation(nextSelectedConversationId);
    setConversationIds(validConversationIds);
    setClosingConversations(closing.filter((id) => id !== conversationId));
  }

  async function handleReopenConversation(conversationId: string) {
    const validConversationIds = conversations.map((c) => c.id);
    const nextSelectedConversationId = getNextSelectedConversationId(
      selectedConversationId,
      validConversationIds
    );

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

    await sleep(400);

    handleSelectConversation(nextSelectedConversationId);
    setConversationIds(validConversationIds);
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

  function handleSendNewMessage(message: Partial<Message>) {
    if (!selectedConversationId) {
      return;
    }

    handleSendMessage({
      conversation_id: selectedConversationId,
      ...message,
    });
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
          left: CONVERSATIONS_DASHBOARD_SIDER_OFFSET,
        }}
      >
        <Box sx={{borderBottom: '1px solid #f0f0f0'}}>
          <Box px={3} py={3}>
            <Title level={3} style={{marginBottom: 0, marginTop: 8}}>
              {title}
            </Title>
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
          marginLeft: CONVERSATIONS_DASHBOARD_OFFSET,
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
            onSendMessage={handleSendNewMessage}
          />
        ) : null}
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

const Wrapper = (props: RouteComponentProps<{bucket: string}>) => {
  const {bucket} = props.match.params;
  const [account, setAccount] = React.useState<Account | null>(null);
  const [status, setStatus] = React.useState<'loading' | 'success' | 'error'>(
    'loading'
  );
  const [error, setErrorMessage] = React.useState<string | null>(null);
  const {currentUser} = useAuth();

  React.useEffect(() => {
    setStatus('loading');

    API.fetchAccountInfo()
      .then((account) => setAccount(account))
      .then(() => setStatus('success'))
      .catch((error) => {
        setStatus('error');
        setErrorMessage(formatServerError(error));
      });
  }, [bucket]);

  if (!isValidBucket(bucket)) {
    // TODO: render error or redirect to default
    return null;
  }

  if (error || status === 'error') {
    // TODO: render better error state?
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
  } else if (status === 'loading') {
    return null;
  } else if (!account || !currentUser) {
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

  return (
    <ConversationsDashboard
      title={title}
      account={account}
      currentUser={currentUser}
      filter={filter}
      isValidConversation={isValidConversation}
    />
  );
};

export default Wrapper;
