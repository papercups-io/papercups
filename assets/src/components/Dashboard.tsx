import React, {useEffect, useRef, useState} from 'react';
import {
  useLocation,
  Switch,
  Redirect,
  Route,
  Link,
  RouteComponentProps,
} from 'react-router-dom';
import {Helmet} from 'react-helmet';
import {Box, Flex} from 'theme-ui';
import {ChatWidget, Papercups} from '@papercups-io/chat-widget';
// import {Storytime} from '../lib/storytime'; // For testing
import {Storytime} from '@papercups-io/storytime';
import {colors, Badge, Layout, Menu, Sider} from './common';
import {
  ApiOutlined,
  CodeOutlined,
  LineChartOutlined,
  LogoutOutlined,
  MailOutlined,
  SettingOutlined,
  SmileOutlined,
  TeamOutlined,
  VideoCameraOutlined,
} from './icons';
import {
  BASE_URL,
  env,
  isDev,
  isEuEdition,
  isHostedProd,
  isStorytimeEnabled,
} from '../config';
import {SOCKET_URL} from '../socket';
import analytics from '../analytics';
import {
  formatUserExternalId,
  getBrowserVisibilityInfo,
  hasValidStripeKey,
  isWindowHidden,
} from '../utils';
import {Account, User} from '../types';
import {useAuth} from './auth/AuthProvider';
import {SocketProvider, SocketContext} from './auth/SocketProvider';
import AccountOverview from './settings/AccountOverview';
import TeamOverview from './settings/TeamOverview';
import UserProfile from './settings/UserProfile';
import ChatWidgetSettings from './settings/ChatWidgetSettings';
import {
  ConversationsProvider,
  useConversations,
} from './conversations/ConversationsProvider';
import AllConversations from './conversations/AllConversations';
import MyConversations from './conversations/MyConversations';
import PriorityConversations from './conversations/PriorityConversations';
import ClosedConversations from './conversations/ClosedConversations';
import ConversationsBySource from './conversations/ConversationsBySource';
import IntegrationsOverview from './integrations/IntegrationsOverview';
import {
  SlackIntegrationDetails,
  SlackReplyIntegrationDetails,
  SlackSyncIntegrationDetails,
} from './integrations/SlackIntegrationDetails';
import BillingOverview from './billing/BillingOverview';
import CustomersPage from './customers/CustomersPage';
import CustomerDetailsPage from './customers/CustomerDetailsPage';
import CustomerDetailsPageV2 from './customers/CustomerDetailsPageV2';
import SessionsOverview from './sessions/SessionsOverview';
import InstallingStorytime from './sessions/InstallingStorytime';
import LiveSessionViewer from './sessions/LiveSessionViewer';
import ReportingDashboard from './reporting/ReportingDashboard';
import CompaniesPage from './companies/CompaniesPage';
import CreateCompanyPage from './companies/CreateCompanyPage';
import UpdateCompanyPage from './companies/UpdateCompanyPage';
import CompanyDetailsPage from './companies/CompanyDetailsPage';
import GettingStarted from './getting-started/GettingStarted';
import TagsOverview from './tags/TagsOverview';
import TagDetailsPage from './tags/TagDetailsPage';
import IssuesOverview from './issues/IssuesOverview';
import IssueDetailsPage from './issues/IssueDetailsPage';
import NotesOverview from './notes/NotesOverview';
import PersonalApiKeysPage from './developers/PersonalApiKeysPage';
import EventSubscriptionsPage from './developers/EventSubscriptionsPage';
import LambdaDetailsPage from './lambdas/LambdaDetailsPage';
import LambdasOverview from './lambdas/LambdasOverview';

const {
  REACT_APP_ADMIN_ACCOUNT_ID = 'eb504736-0f20-4978-98ff-1a82ae60b266',
} = env;

const TITLE_FLASH_INTERVAL = 2000;

const shouldDisplayChat = (pathname: string) => {
  return isHostedProd && pathname !== '/settings/chat-widget';
};

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

const useWindowVisibility = (d?: Document) => {
  const doc = d || document || window.document;
  const [isWindowVisible, setWindowVisible] = useState(!isWindowHidden(doc));

  useEffect(() => {
    const {event} = getBrowserVisibilityInfo(doc);
    const handler = () => setWindowVisible(!isWindowHidden(doc));

    if (!event) {
      return;
    }

    doc.addEventListener(event, handler, false);

    return () => doc.removeEventListener(event, handler);
  }, [doc]);

  return isWindowVisible;
};

const ChatWithUs = ({
  currentUser,
  account,
}: {
  currentUser: User;
  account?: Account | null;
}) => {
  if (isEuEdition) {
    return (
      <ChatWidget
        title="Need help with anything?"
        subtitle="Ask us in the chat window below 😊"
        greeting="Hi there! Send us a message and we'll get back to you as soon as we can."
        primaryColor="#1890ff"
        accountId={REACT_APP_ADMIN_ACCOUNT_ID}
        hideToggleButton
        baseUrl="https://app.papercups-eu.io"
        customer={{
          external_id: formatUserExternalId(currentUser),
          email: currentUser.email,
          metadata: {
            company_name: account?.company_name,
            subscription_plan: account?.subscription_plan,
            edition: 'EU',
          },
        }}
      />
    );
  }

  return (
    <ChatWidget
      title="Need help with anything?"
      subtitle="Ask us in the chat window below 😊"
      greeting="Hi there! Send us a message and we'll get back to you as soon as we can."
      primaryColor="#1890ff"
      accountId={REACT_APP_ADMIN_ACCOUNT_ID}
      hideToggleButton
      customer={{
        external_id: formatUserExternalId(currentUser),
        email: currentUser.email,
        metadata: {
          company_name: account?.company_name,
          subscription_plan: account?.subscription_plan,
          edition: 'US',
        },
      }}
    />
  );
};

// TODO: not sure if this is the best way to handle this, but the goal
// of this component is to flash the number of unread messages in the
// tab (i.e. HTML title) so users can see when new messages arrive
const DashboardHtmlHead = ({totalNumUnread}: {totalNumUnread: number}) => {
  const doc = document || window.document;
  const [htmlTitle, setHtmlTitle] = useState('Papercups');
  const isWindowVisible = useWindowVisibility(doc);
  const timer = useRef<any>();

  const hasDefaultTitle = (title: string) => title.startsWith('Papercups');

  const toggleNotificationMessage = () => {
    if (totalNumUnread > 0 && hasDefaultTitle(htmlTitle) && !isWindowVisible) {
      setHtmlTitle(
        `(${totalNumUnread}) New message${totalNumUnread === 1 ? '' : 's'}!`
      );
    } else {
      setHtmlTitle('Papercups');
    }
  };

  useEffect(() => {
    const shouldToggle =
      totalNumUnread > 0 && (!isWindowVisible || !hasDefaultTitle(htmlTitle));

    if (shouldToggle) {
      timer.current = setTimeout(
        toggleNotificationMessage,
        TITLE_FLASH_INTERVAL
      );
    } else {
      clearTimeout(timer.current);
    }

    return () => clearTimeout(timer.current);
  });

  return (
    <Helmet defer={false}>
      <title>{totalNumUnread ? htmlTitle : 'Papercups'}</title>
    </Helmet>
  );
};

const Dashboard = (props: RouteComponentProps) => {
  const auth = useAuth();
  const {pathname} = useLocation();
  const {account, currentUser, inboxes, getUnreadCount} = useConversations();

  const [section, key] = getSectionKey(pathname);
  const totalNumUnread = getUnreadCount(inboxes.all.open);
  const shouldDisplayBilling = hasValidStripeKey();

  const logout = () => auth.logout().then(() => props.history.push('/login'));

  useEffect(() => {
    if (currentUser && currentUser.id) {
      const {id, email} = currentUser;

      analytics.identify(id, email);
    }

    if (isStorytimeEnabled && currentUser) {
      const {email} = currentUser;
      // TODO: figure out a better way to initialize this?
      const storytime = Storytime.init({
        accountId: REACT_APP_ADMIN_ACCOUNT_ID,
        baseUrl: BASE_URL,
        debug: isDev,
        customer: {
          email,
          external_id: formatUserExternalId(currentUser),
        },
      });

      return () => storytime.finish();
    }
  }, [currentUser]);

  return (
    <Layout>
      <DashboardHtmlHead totalNumUnread={totalNumUnread} />

      <Sider
        width={220}
        collapsed={false}
        style={{
          overflow: 'auto',
          height: '100vh',
          position: 'fixed',
          left: 0,
          color: colors.white,
        }}
      >
        <Flex sx={{flexDirection: 'column', height: '100%'}}>
          <Box py={3} sx={{flex: 1}}>
            <Menu
              selectedKeys={[section, key]}
              defaultOpenKeys={[section, 'conversations']}
              mode="inline"
              theme="dark"
            >
              <Menu.Item key="getting-started">
                <Link to="/getting-started">Getting Started</Link>
              </Menu.Item>
              <Menu.SubMenu
                key="conversations"
                icon={<MailOutlined />}
                title="Inbox"
              >
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
                        count={getUnreadCount(inboxes.all.assigned)}
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
                        count={getUnreadCount(inboxes.all.priority)}
                        style={{borderColor: '#FF4D4F'}}
                      />
                    </Flex>
                  </Link>
                </Menu.Item>
                <Menu.Item key="closed">
                  <Link to="/conversations/closed">Closed</Link>
                </Menu.Item>
              </Menu.SubMenu>
              <Menu.SubMenu
                key="channels"
                icon={<MailOutlined />}
                title="Channels"
              >
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
                        count={getUnreadCount(inboxes.bySource['chat'] ?? [])}
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
                        count={getUnreadCount(inboxes.bySource['email'] ?? [])}
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
                        count={getUnreadCount(inboxes.bySource['slack'] ?? [])}
                        style={{borderColor: '#FF4D4F'}}
                      />
                    </Flex>
                  </Link>
                </Menu.Item>
              </Menu.SubMenu>
              <Menu.SubMenu
                key="customers"
                icon={<TeamOutlined />}
                title="Customers"
              >
                <Menu.Item key="people">
                  <Link to="/customers">People</Link>
                </Menu.Item>
                <Menu.Item key="companies">
                  <Link to="/companies">Companies</Link>
                </Menu.Item>
                <Menu.Item key="tags">
                  <Link to="/tags">Tags</Link>
                </Menu.Item>
                <Menu.Item key="issues">
                  <Link to="/issues">Issues</Link>
                </Menu.Item>
                <Menu.Item key="notes">
                  <Link to="/notes">Notes</Link>
                </Menu.Item>
              </Menu.SubMenu>
              <Menu.SubMenu
                key="sessions"
                icon={<VideoCameraOutlined />}
                title="Sessions"
              >
                <Menu.Item key="list">
                  <Link to="/sessions/list">Live sessions</Link>
                </Menu.Item>
                <Menu.Item key="setup">
                  <Link to="/sessions/setup">Set up Storytime</Link>
                </Menu.Item>
              </Menu.SubMenu>
              <Menu.SubMenu
                key="developers"
                icon={<CodeOutlined />}
                title="Developers"
              >
                <Menu.Item key="personal-api-keys">
                  <Link to="/developers/personal-api-keys">API keys</Link>
                </Menu.Item>
                <Menu.Item key="event-subscriptions">
                  <Link to="/developers/event-subscriptions">
                    Event subscriptions
                  </Link>
                </Menu.Item>
                <Menu.Item key="functions">
                  <Link to="/functions">Functions</Link>
                </Menu.Item>
              </Menu.SubMenu>
              <Menu.Item
                title="Reporting"
                icon={<LineChartOutlined />}
                key="reporting"
              >
                <Link to="/reporting">Reporting</Link>
              </Menu.Item>
              <Menu.Item
                title="Integrations"
                icon={<ApiOutlined />}
                key="integrations"
              >
                <Link to="/integrations">Integrations</Link>
              </Menu.Item>
              <Menu.SubMenu
                key="settings"
                icon={<SettingOutlined />}
                title="Settings"
              >
                <Menu.Item key="account">
                  <Link to="/settings/account">Account</Link>
                </Menu.Item>
                <Menu.Item key="team">
                  <Link to="/settings/team">My team</Link>
                </Menu.Item>
                <Menu.Item key="profile">
                  <Link to="/settings/profile">My profile</Link>
                </Menu.Item>
                <Menu.Item key="chat-widget">
                  <Link to="/settings/chat-widget">Chat widget</Link>
                </Menu.Item>
                {shouldDisplayBilling && (
                  <Menu.Item key="billing">
                    <Link to="/settings/billing">Billing</Link>
                  </Menu.Item>
                )}
              </Menu.SubMenu>
            </Menu>
          </Box>

          <Box py={3}>
            <Menu mode="inline" theme="dark" selectable={false}>
              {shouldDisplayChat(pathname) && (
                <Menu.Item
                  title="Chat with us!"
                  icon={<SmileOutlined />}
                  key="chat"
                  onClick={Papercups.toggle}
                >
                  Chat with us!
                </Menu.Item>
              )}
              <Menu.Item
                title="Log out"
                icon={<LogoutOutlined />}
                key="logout"
                onClick={logout}
              >
                Log out
              </Menu.Item>
            </Menu>
          </Box>
        </Flex>
      </Sider>

      <Layout style={{marginLeft: 220, background: colors.white}}>
        <Switch>
          <Route path="/getting-started" component={GettingStarted} />

          {/* Temporary redirect routes to point from /accounts/* to /settings/* */}
          <Redirect from="/account/overview" to="/settings/overview" />
          <Redirect from="/account/team" to="/settings/team" />
          <Redirect from="/account/profile" to="/settings/profile" />
          <Redirect
            from="/account/getting-started"
            to="/settings/chat-widget"
          />
          <Redirect from="/account*" to="/settings*" />

          <Route path="/settings/account" component={AccountOverview} />
          <Route path="/settings/team" component={TeamOverview} />
          <Route path="/settings/profile" component={UserProfile} />
          <Route path="/settings/chat-widget" component={ChatWidgetSettings} />
          {shouldDisplayBilling && (
            <Route path="/settings/billing" component={BillingOverview} />
          )}
          <Route path="/settings*" component={AccountOverview} />
          <Route path="/v1/customers/:id" component={CustomerDetailsPage} />
          <Route path="/customers/:id" component={CustomerDetailsPageV2} />
          <Route path="/customers" component={CustomersPage} />
          <Route path="/companies/new" component={CreateCompanyPage} />
          <Route path="/companies/:id/edit" component={UpdateCompanyPage} />
          <Route path="/companies/:id" component={CompanyDetailsPage} />
          <Route path="/companies" component={CompaniesPage} />
          <Route
            path="/integrations/slack/reply"
            component={SlackReplyIntegrationDetails}
          />
          <Route
            path="/integrations/slack/support"
            component={SlackSyncIntegrationDetails}
          />
          <Route
            path="/integrations/slack"
            component={SlackIntegrationDetails}
          />
          <Route path="/integrations/:type" component={IntegrationsOverview} />
          <Route path="/integrations" component={IntegrationsOverview} />
          <Route path="/integrations*" component={IntegrationsOverview} />
          <Route
            path="/developers/personal-api-keys"
            component={PersonalApiKeysPage}
          />
          <Route
            path="/developers/event-subscriptions"
            component={EventSubscriptionsPage}
          />
          <Route path="/functions/:id" component={LambdaDetailsPage} />
          <Route path="/functions" component={LambdasOverview} />
          <Route path="/conversations/all" component={AllConversations} />
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

              return (
                <Redirect to={`/conversations/all?cid=${conversationId}`} />
              );
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
          <Route path="/reporting" component={ReportingDashboard} />
          <Route path="/sessions/live/:session" component={LiveSessionViewer} />
          <Route path="/sessions/list" component={SessionsOverview} />
          <Route path="/sessions/setup" component={InstallingStorytime} />
          <Route path="/sessions*" component={SessionsOverview} />
          <Route path="/tags/:id" component={TagDetailsPage} />
          <Route path="/tags" component={TagsOverview} />
          <Route path="/issues/:id" component={IssueDetailsPage} />
          <Route path="/issues" component={IssuesOverview} />
          <Route path="/notes" component={NotesOverview} />
          <Route path="*" render={() => <Redirect to="/conversations/all" />} />
        </Switch>
      </Layout>

      {currentUser && shouldDisplayChat(pathname) && (
        <ChatWithUs currentUser={currentUser} account={account} />
      )}
    </Layout>
  );
};

const DashboardWrapper = (props: RouteComponentProps) => {
  const {refresh} = useAuth();

  return (
    <SocketProvider url={SOCKET_URL} refresh={refresh}>
      <SocketContext.Consumer>
        {({socket}) => {
          return (
            <ConversationsProvider socket={socket}>
              <Dashboard {...props} />
            </ConversationsProvider>
          );
        }}
      </SocketContext.Consumer>
    </SocketProvider>
  );
};

export default DashboardWrapper;
