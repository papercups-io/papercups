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
import {
  DASHBOARD_COLLAPSED_SIDER_WIDTH,
  INBOXES_DASHBOARD_SIDER_WIDTH,
} from '../../utils';
import * as API from '../../api';
import {Inbox} from '../../types';
import {useConversations} from '../conversations/ConversationsProvider';
import InboxConversations from './InboxConversations';
import ConversationsDashboard from '../conversations/ConversationsDashboard';

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
  const {unread} = useConversations();
  const [inboxes, setCustomInboxes] = React.useState<Array<Inbox>>([]);

  const [section, key] = getSectionKey(pathname);
  const totalNumUnread = unread.conversations.open || 0;

  React.useEffect(() => {
    API.fetchInboxes().then((inboxes) => setCustomInboxes(inboxes));
  }, []);

  return (
    <Layout style={{background: colors.white}}>
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
            {/* TODO: eventually we should design our own sidebar menu so we have more control over the UX */}
            <Menu
              selectedKeys={[section, key]}
              defaultOpenKeys={['conversations', 'channels', 'inboxes']}
              mode="inline"
              theme="dark"
            >
              <Menu.SubMenu key="conversations" title="Conversations">
                <Menu.Item key="all">
                  <Link to="/conversations/all">
                    <Flex
                      sx={{
                        alignItems: 'center',
                        justifyContent: 'space-between',
                      }}
                    >
                      <Box mr={2}>All</Box>
                      <Badge
                        count={totalNumUnread}
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
                        count={unread.conversations.assigned || 0}
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
                        count={unread.conversations.mentioned || 0}
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
                      <Box mr={2}>Unread</Box>
                      <Badge
                        count={unread.conversations.unread || 0}
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
                        count={unread.conversations.unassigned}
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
                        count={unread.conversations.priority}
                        style={{borderColor: '#FF4D4F'}}
                      />
                    </Flex>
                  </Link>
                </Menu.Item>
                <Menu.Item key="closed">
                  <Link to="/conversations/closed">Closed</Link>
                </Menu.Item>
              </Menu.SubMenu>

              <Menu.SubMenu key="inboxes" title="Inboxes">
                {inboxes.map((inbox) => {
                  const {id, name} = inbox;

                  return (
                    <Menu.Item key={id}>
                      <Link to={`/inboxes/${id}/conversations`}>
                        <Flex
                          sx={{
                            alignItems: 'center',
                            justifyContent: 'space-between',
                          }}
                        >
                          <Box mr={2}>{name}</Box>
                          <Badge
                            count={unread.inboxes[id] || 0}
                            style={{borderColor: '#FF4D4F'}}
                          />
                        </Flex>
                      </Link>
                    </Menu.Item>
                  );
                })}
              </Menu.SubMenu>
            </Menu>
          </Box>
        </Flex>
      </Sider>

      <Switch>
        <Route
          path="/conversations/:bucket"
          component={ConversationsDashboard}
        />
        <Route
          path="/inboxes/:id/conversations"
          component={InboxConversations}
        />
        <Route path="*" render={() => <Redirect to="/conversations/all" />} />
      </Switch>
    </Layout>
  );
};

export default InboxesDashboard;
