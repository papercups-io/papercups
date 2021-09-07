import React from 'react';
import {
  useLocation,
  Switch,
  Redirect,
  Route,
  Link,
  RouteComponentProps,
} from 'react-router-dom';
import {Box, Flex} from 'theme-ui';

import {colors, Badge, Layout, Menu, Sider} from '../common';
import {useConversations} from '../conversations/ConversationsProvider';
import AllConversations from '../conversations/AllConversations';
import MyConversations from '../conversations/MyConversations';
import MentionedConversations from '../conversations/MentionedConversations';
import PriorityConversations from '../conversations/PriorityConversations';
import UnreadConversations from '../conversations/UnreadConversations';
import UnassignedConversations from '../conversations/UnassignedConversations';
import ClosedConversations from '../conversations/ClosedConversations';
import ConversationsBySource from '../conversations/ConversationsBySource';
import {
  DASHBOARD_COLLAPSED_SIDER_WIDTH,
  INBOXES_DASHBOARD_SIDER_WIDTH,
} from '../../utils';

const getSectionKey = (pathname: string) => {
  if (pathname.startsWith('/companies')) {
    return ['customers', 'companies'];
  } else if (pathname.startsWith('/customers')) {
    return ['customers', 'people'];
  } else if (pathname.startsWith('/tags')) {
    return ['customers', 'tags'];
  } else if (pathname.startsWith('/notes')) {
    return ['customers', 'notes'];
  } else if (pathname.startsWith('/functions')) {
    return ['developers', 'functions'];
  } else {
    return pathname.split('/').slice(1); // Slice off initial slash
  }
};

const InboxesDashboard = (props: RouteComponentProps) => {
  const {pathname} = useLocation();
  const {inboxes, getUnreadCount} = useConversations();

  const [section, key] = getSectionKey(pathname);
  const totalNumUnread = getUnreadCount('open', inboxes.all.open);

  return (
    <Layout>
      <Sider
        className="Dashboard-Sider"
        width={INBOXES_DASHBOARD_SIDER_WIDTH}
        style={{
          overflow: 'auto',
          height: '100vh',
          position: 'fixed',
          left: DASHBOARD_COLLAPSED_SIDER_WIDTH,
          color: colors.white,
        }}
      >
        <Flex sx={{flexDirection: 'column', height: '100%'}}>
          <Box py={3} sx={{flex: 1}}>
            <Menu
              selectedKeys={[section, key]}
              defaultOpenKeys={['conversations', 'channels']}
              mode="inline"
              theme="dark"
            >
              <Menu.SubMenu key="conversations" title="Inbox">
                <Menu.Item key="all">
                  <Link to="/conversations/all">
                    <Flex
                      sx={{
                        alignItems: 'center',
                        justifyContent: 'space-between',
                      }}
                    >
                      <Box mr={2}>All conversations</Box>
                      <Badge
                        count={totalNumUnread}
                        style={{borderColor: '#FF4D4F'}}
                      />
                    </Flex>
                  </Link>
                </Menu.Item>
                <Menu.Item key="unread">
                  <Link to="/conversations/unread">
                    <Flex
                      sx={{
                        alignItems: 'center',
                        justifyContent: 'space-between',
                      }}
                    >
                      <Box mr={2}>All unread</Box>
                      <Badge
                        count={getUnreadCount('unread', inboxes.all.unread)}
                        style={{borderColor: '#FF4D4F'}}
                      />
                    </Flex>
                  </Link>
                </Menu.Item>
                <Menu.Item key="unassigned">
                  <Link to="/conversations/unassigned">
                    <Flex
                      sx={{
                        alignItems: 'center',
                        justifyContent: 'space-between',
                      }}
                    >
                      <Box mr={2}>Unassigned</Box>
                      <Badge
                        count={getUnreadCount(
                          'unassigned',
                          inboxes.all.unassigned
                        )}
                        style={{borderColor: '#FF4D4F'}}
                      />
                    </Flex>
                  </Link>
                </Menu.Item>
                <Menu.Item key="mentions">
                  <Link to="/conversations/mentions">
                    <Flex
                      sx={{
                        alignItems: 'center',
                        justifyContent: 'space-between',
                      }}
                    >
                      <Box mr={2}>Mentions</Box>
                      <Badge
                        count={getUnreadCount(
                          'mentioned',
                          inboxes.all.mentioned
                        )}
                        style={{borderColor: '#FF4D4F'}}
                      />
                    </Flex>
                  </Link>
                </Menu.Item>
                <Menu.Item key="me">
                  <Link to="/conversations/me">
                    <Flex
                      sx={{
                        alignItems: 'center',
                        justifyContent: 'space-between',
                      }}
                    >
                      <Box mr={2}>Assigned to me</Box>
                      <Badge
                        count={getUnreadCount('assigned', inboxes.all.assigned)}
                        style={{borderColor: '#FF4D4F'}}
                      />
                    </Flex>
                  </Link>
                </Menu.Item>
                <Menu.Item key="priority">
                  <Link to="/conversations/priority">
                    <Flex
                      sx={{
                        alignItems: 'center',
                        justifyContent: 'space-between',
                      }}
                    >
                      <Box mr={2}>Prioritized</Box>
                      <Badge
                        count={getUnreadCount('priority', inboxes.all.priority)}
                        style={{borderColor: '#FF4D4F'}}
                      />
                    </Flex>
                  </Link>
                </Menu.Item>
                <Menu.Item key="closed">
                  <Link to="/conversations/closed">Closed</Link>
                </Menu.Item>
              </Menu.SubMenu>
              <Menu.SubMenu key="channels" title="Channels">
                <Menu.Item key="live-chat">
                  <Link to="/channels/live-chat">
                    <Flex
                      sx={{
                        alignItems: 'center',
                        justifyContent: 'space-between',
                      }}
                    >
                      <Box mr={2}>Live chat</Box>
                      <Badge
                        count={getUnreadCount(
                          'chat',
                          inboxes.bySource['chat'] ?? []
                        )}
                        style={{borderColor: '#FF4D4F'}}
                      />
                    </Flex>
                  </Link>
                </Menu.Item>
                <Menu.Item key="email">
                  <Link to="/channels/email">
                    <Flex
                      sx={{
                        alignItems: 'center',
                        justifyContent: 'space-between',
                      }}
                    >
                      <Box mr={2}>Email</Box>
                      <Badge
                        count={getUnreadCount(
                          'email',
                          inboxes.bySource['email'] ?? []
                        )}
                        style={{borderColor: '#FF4D4F'}}
                      />
                    </Flex>
                  </Link>
                </Menu.Item>
                <Menu.Item key="slack">
                  <Link to="/channels/slack">
                    <Flex
                      sx={{
                        alignItems: 'center',
                        justifyContent: 'space-between',
                      }}
                    >
                      <Box mr={2}>Slack</Box>
                      <Badge
                        count={getUnreadCount(
                          'slack',
                          inboxes.bySource['slack'] ?? []
                        )}
                        style={{borderColor: '#FF4D4F'}}
                      />
                    </Flex>
                  </Link>
                </Menu.Item>
              </Menu.SubMenu>
            </Menu>
          </Box>
        </Flex>
      </Sider>

      {/* <Layout
        style={{
          marginLeft: DASHBOARD_COLLAPSED_SIDER_WIDTH,
          background: colors.white,
        }}
      > */}
      <Switch>
        <Route path="/conversations/all" component={AllConversations} />
        <Route path="/conversations/unread" component={UnreadConversations} />
        <Route
          path="/conversations/unassigned"
          component={UnassignedConversations}
        />
        <Route
          path="/conversations/mentions"
          component={MentionedConversations}
        />
        <Route path="/conversations/me" component={MyConversations} />
        <Route
          path="/conversations/priority"
          component={PriorityConversations}
        />
        <Route path="/conversations/closed" component={ClosedConversations} />
        <Route
          path="/conversations/:id"
          render={(props: RouteComponentProps<{id: string}>) => {
            const {id: conversationId} = props.match.params;

            return <Redirect to={`/conversations/all?cid=${conversationId}`} />;
          }}
        />
        <Route path="/channels/live-chat" key="chat">
          <ConversationsBySource title="Live chat" source="chat" />
        </Route>
        <Route path="/channels/email" key="email">
          <ConversationsBySource title="Email" source="email" />
        </Route>
        <Route path="/channels/slack" key="slack">
          <ConversationsBySource title="Slack" source="slack" />
        </Route>

        <Route path="*" render={() => <Redirect to="/conversations/all" />} />
      </Switch>
      {/* </Layout> */}
    </Layout>
  );
};

export default InboxesDashboard;
