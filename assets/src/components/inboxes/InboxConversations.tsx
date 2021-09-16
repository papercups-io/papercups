import React from 'react';
import {RouteComponentProps} from 'react-router';
import {Box, Flex} from 'theme-ui';

import * as API from '../../api';
import {Account, Conversation, Inbox, Message, User} from '../../types';
import {colors, Layout, notification, Result, Sider, Title} from '../common';
import {
  CONVERSATIONS_DASHBOARD_OFFSET,
  CONVERSATIONS_DASHBOARD_SIDER_OFFSET,
  CONVERSATIONS_DASHBOARD_SIDER_WIDTH,
  formatServerError,
  sleep,
} from '../../utils';
import ConversationsPreviewList from '../conversations/ConversationsPreviewList';
import SelectedConversationContainer from '../conversations/SelectedConversationContainer';
import ConversationHeader from '../conversations/ConversationHeader';
import {useConversations} from '../conversations/ConversationsProvider';
import {isUnreadConversation} from '../conversations/support';
import {useNotifications} from '../conversations/NotificationsProvider';
import {useAuth} from '../auth/AuthProvider';
import {ConversationsDashboard} from '../conversations/ConversationsDashboard';

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

// TODO: verify that ConversationsDashboard actually works as a substitute

// export const InboxConversations = ({
//   inbox,
//   account,
//   currentUser,
//   filter = {},
//   isValidConversation = defaultConversationFilter,
// }: {
//   inbox: Inbox;
//   account: Account;
//   currentUser: User;
//   filter: Record<string, any>;
//   isValidConversation: (conversation: Conversation) => boolean;
// }) => {
//   const {id: inboxId} = inbox;
//   const scrollToEl = React.useRef<any>(null);
//   const [status, setStatus] = React.useState<'loading' | 'success' | 'error'>(
//     'loading'
//   );
//   const [error, setErrorMessage] = React.useState<string | null>(null);
//   const [conversationIds, setConversationIds] = React.useState<Array<string>>(
//     []
//   );
//   const [pagination, setPaginationOptions] = React.useState<
//     API.PaginationOptions
//   >({});
//   const [selectedConversationId, setSelectedConversationId] = React.useState<
//     string | null
//   >(null);
//   const [closing, setClosingConversations] = React.useState<Array<string>>([]);

//   const {
//     fetchConversations,
//     getValidConversations,
//     getConversationById,
//     getMessagesByConversationId,
//     updateConversationById,
//     archiveConversationById,
//   } = useConversations();

//   const {handleSendMessage, handleConversationSeen} = useNotifications();

//   const {users = []} = account;
//   // TODO: is there a more efficient way to do this?
//   const conversations = getValidConversations(isValidConversation);
//   const hasMoreConversations =
//     !!pagination.next &&
//     !!pagination.total &&
//     conversations.length < pagination.total;
//   const isClosingSelected =
//     !!selectedConversationId && closing.indexOf(selectedConversationId) !== -1;
//   const conversation = getConversationById(selectedConversationId);
//   const messages = getMessagesByConversationId(selectedConversationId);

//   React.useEffect(() => {
//     setStatus('loading');

//     fetchFilteredConversations()
//       .then((result) => {
//         const {data: conversations, ...pagination} = result;
//         const conversationIds = conversations.map((c) => c.id);
//         const [first] = conversationIds;
//         // TODO: should we handle conversation IDs and pagination options here,
//         // or in the ConversationsProvider? (Might need to keep pagination here)
//         setConversationIds(conversationIds);
//         setPaginationOptions(pagination);
//         handleSelectConversation(first || null);
//       })
//       .then(() => setStatus('success'))
//       .catch((error) => {
//         setStatus('error');
//         setErrorMessage(formatServerError(error));
//       });
//     // FIXME?
//     // eslint-disable-next-line
//   }, [inboxId]);

//   React.useEffect(() => {
//     scrollToEl.current?.scrollIntoView();
//   }, [inboxId, selectedConversationId, messages.length]);

//   function setScrollRef(el: any) {
//     scrollToEl.current = el || null;
//     scrollToEl.current?.scrollIntoView();
//   }

//   function fetchFilteredConversations(params = {}) {
//     return fetchConversations({...filter, ...params});
//   }

//   function handleSelectConversation(conversationId: string | null) {
//     setSelectedConversationId(conversationId);

//     if (!conversationId) {
//       return;
//     }

//     const selected = getConversationById(conversationId);

//     if (selected && isUnreadConversation(selected, currentUser)) {
//       handleConversationSeen(conversationId);
//     }

//     // TODO: history.push(/inboxes/:inbox_id/conversations/:conversation_id)
//   }

//   async function handleLoadMoreConversations() {
//     const {data = [], ...nextPaginationOptions} = await fetchConversations({
//       after: pagination.next,
//     });

//     setConversationIds([
//       ...new Set([...conversationIds, ...data.map((c) => c.id)]),
//     ]);
//     setPaginationOptions(nextPaginationOptions);
//   }

//   async function handleAssignUser(
//     conversationId: string,
//     userId: string | null
//   ) {
//     await updateConversationById(conversationId, {assignee_id: userId});
//   }

//   async function handleMarkPriority(conversationId: string) {
//     await updateConversationById(conversationId, {
//       priority: 'priority',
//     });
//   }

//   async function handleRemovePriority(conversationId: string) {
//     await updateConversationById(conversationId, {
//       priority: 'not_priority',
//     });
//   }

//   async function handleCloseConversation(conversationId: string) {
//     setClosingConversations([...closing, conversationId]);

//     const validConversationIds = conversations.map((c) => c.id);
//     const nextSelectedConversationId = getNextSelectedConversationId(
//       selectedConversationId,
//       validConversationIds
//     );

//     // TODO: figure out the best way to handle this when closing multiple
//     // conversations in a row very quickly
//     await sleep(400);
//     await updateConversationById(conversationId, {status: 'closed'});

//     handleSelectConversation(nextSelectedConversationId);
//     setConversationIds(validConversationIds);
//     setClosingConversations(closing.filter((id) => id !== conversationId));
//   }

//   async function handleReopenConversation(conversationId: string) {
//     const validConversationIds = conversations.map((c) => c.id);
//     const nextSelectedConversationId = getNextSelectedConversationId(
//       selectedConversationId,
//       validConversationIds
//     );

//     await updateConversationById(conversationId, {status: 'open'});

//     notification.open({
//       message: 'Conversation re-opened!',
//       duration: 2, // 2 seconds
//       description: (
//         <Box>
//           You can view this conversations once again{' '}
//           <a href="/conversations/all">here</a>.
//         </Box>
//       ),
//     });

//     await sleep(400);

//     handleSelectConversation(nextSelectedConversationId);
//     setConversationIds(validConversationIds);
//   }

//   async function handleDeleteConversation(conversationId: string) {
//     const validConversationIds = conversations.map((c) => c.id);
//     const nextSelectedConversationId = getNextSelectedConversationId(
//       selectedConversationId,
//       validConversationIds
//     );

//     await archiveConversationById(conversationId);

//     notification.open({
//       message: 'Conversation deleted!',
//       duration: 2, // 2 seconds
//       description: (
//         <Box>
//           This conversation was permanently deleted. You can view your active
//           conversations <a href="/conversations/all">here</a>.
//         </Box>
//       ),
//     });

//     await sleep(400);

//     handleSelectConversation(nextSelectedConversationId);
//     setConversationIds(validConversationIds);
//   }

//   function handleSendNewMessage(message: Partial<Message>) {
//     if (!selectedConversationId) {
//       return;
//     }

//     handleSendMessage({
//       conversation_id: selectedConversationId,
//       ...message,
//     });
//   }

//   if (error) {
//     return (
//       <Flex
//         sx={{
//           flex: 1,
//           justifyContent: 'center',
//           alignItems: 'center',
//           height: '100%',
//         }}
//       >
//         <Result
//           status="error"
//           title="Error retrieving inbox"
//           subTitle={error || 'Unknown error'}
//         />
//       </Flex>
//     );
//   }

//   return (
//     <Layout style={{background: colors.white}}>
//       <Sider
//         theme="light"
//         width={CONVERSATIONS_DASHBOARD_SIDER_WIDTH}
//         style={{
//           borderRight: '1px solid #f0f0f0',
//           overflow: 'auto',
//           height: '100vh',
//           position: 'fixed',
//           left: CONVERSATIONS_DASHBOARD_SIDER_OFFSET,
//         }}
//       >
//         <Box sx={{borderBottom: '1px solid #f0f0f0'}}>
//           <Box px={3} py={3}>
//             <Title level={3} style={{marginBottom: 0, marginTop: 8}}>
//               {inbox.name}
//             </Title>
//           </Box>
//         </Box>

//         <ConversationsPreviewList
//           loading={status === 'loading'}
//           conversations={conversations}
//           selectedConversationId={selectedConversationId}
//           hasMoreConversations={hasMoreConversations}
//           isConversationClosing={(conversationId) =>
//             closing.indexOf(conversationId) !== -1
//           }
//           onSelectConversation={handleSelectConversation}
//           onLoadMoreConversations={handleLoadMoreConversations}
//         />
//       </Sider>

//       <Layout
//         style={{
//           marginLeft: CONVERSATIONS_DASHBOARD_OFFSET,
//           background: colors.white,
//         }}
//       >
//         {conversation && (
//           <ConversationHeader
//             conversation={conversation}
//             users={users}
//             onAssignUser={handleAssignUser}
//             onMarkPriority={handleMarkPriority}
//             onRemovePriority={handleRemovePriority}
//             onCloseConversation={handleCloseConversation}
//             onReopenConversation={handleReopenConversation}
//             onDeleteConversation={handleDeleteConversation}
//           />
//         )}
//         {/* TODO: if no selected conversation, render something else */}
//         {conversation ? (
//           <SelectedConversationContainer
//             loading={status === 'loading'}
//             account={account}
//             currentUser={currentUser}
//             conversation={conversation}
//             isClosing={isClosingSelected}
//             setScrollRef={setScrollRef}
//             onSendMessage={handleSendNewMessage}
//           />
//         ) : null}
//       </Layout>
//     </Layout>
//   );
// };

const Wrapper = (props: RouteComponentProps<{id: string}>) => {
  const {id: inboxId} = props.match.params;
  const [account, setAccount] = React.useState<Account | null>(null);
  const [inbox, setSelectedInbox] = React.useState<Inbox | null>(null);
  const [status, setStatus] = React.useState<'loading' | 'success' | 'error'>(
    'loading'
  );
  const [error, setErrorMessage] = React.useState<string | null>(null);
  const {currentUser} = useAuth();

  React.useEffect(() => {
    setStatus('loading');

    Promise.all([
      API.fetchAccountInfo().then((account) => setAccount(account)),
      API.fetchInbox(inboxId).then((result) => setSelectedInbox(result)),
    ])
      .then(() => setStatus('success'))
      .catch((error) => {
        setStatus('error');
        setErrorMessage(formatServerError(error));
      });
  }, [inboxId]);

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
  } else if (!inbox || !account || !currentUser) {
    return null;
  }

  return (
    <ConversationsDashboard
      title={inbox.name}
      account={account}
      currentUser={currentUser}
      filter={{inbox_id: inboxId, status: 'open'}}
      isValidConversation={(conversation: Conversation) => {
        const {status, inbox_id, archived_at, closed_at} = conversation;

        return (
          inbox_id === inboxId &&
          status === 'open' &&
          !archived_at &&
          !closed_at
        );
      }}
    />
  );
};

export default Wrapper;
