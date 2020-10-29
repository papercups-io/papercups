import React, {useEffect, useState} from 'react';
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
  MailOutlined,
  UserOutlined,
  LineChartOutlined,
  LogoutOutlined,
  CreditCardOutlined,
  SmileOutlined,
  TeamOutlined,
  VideoCameraOutlined,
} from './icons';
import {BASE_URL, isDev} from '../config';
import {useAuth} from './auth/AuthProvider';
import AccountOverview from './account/AccountOverview';
import UserProfile from './account/UserProfile';
import GettingStartedOverview from './account/GettingStartedOverview';
import {
  ConversationsProvider,
  useConversations,
} from './conversations/ConversationsProvider';
import AllConversations from './conversations/AllConversations';
import MyConversations from './conversations/MyConversations';
import PriorityConversations from './conversations/PriorityConversations';
import ClosedConversations from './conversations/ClosedConversations';
import IntegrationsOverview from './integrations/IntegrationsOverview';
import BillingOverview from './billing/BillingOverview';
import CustomersPage from './customers/CustomersPage';
import SessionsOverview from './sessions/SessionsOverview';
import InstallingStorytime from './sessions/InstallingStorytime';
import LiveSessionViewer from './sessions/LiveSessionViewer';
import ReportingDashboard from './reporting/ReportingDashboard';

const {
  REACT_APP_STRIPE_PUBLIC_KEY,
  REACT_APP_STORYTIME_ENABLED,
  REACT_APP_ADMIN_ACCOUNT_ID = 'eb504736-0f20-4978-98ff-1a82ae60b266',
} = process.env;

const TITLE_FLASH_INTERVAL = 2000;

const hasValidStripeKey = () => {
  const key = REACT_APP_STRIPE_PUBLIC_KEY;

  return key && key.startsWith('pk_');
};

const shouldDisplayChat = (pathname: string) => {
  if (pathname === '/account/getting-started') {
    return false;
  }

  return true;
};

const Dashboard = (props: RouteComponentProps) => {
  const auth = useAuth();
  const {pathname} = useLocation();
  const {currentUser, unreadByCategory: unread} = useConversations();
  const [htmlTitle, setHtmlTitle] = useState('Papercups');

  const [section, key] = pathname.split('/').slice(1); // Slice off initial slash
  const totalNumUnread = (unread && unread.all) || 0;
  const shouldDisplayBilling = hasValidStripeKey();

  const logout = () => auth.logout().then(() => props.history.push('/login'));

  const toggleNotificationMessage = () => {
    if (totalNumUnread > 0 && htmlTitle.startsWith('Papercups')) {
      setHtmlTitle(
        `(${totalNumUnread}) New message${totalNumUnread === 1 ? '' : 's'}!`
      );
    } else {
      setHtmlTitle('Papercups');
    }
  };

  useEffect(() => {
    if (REACT_APP_STORYTIME_ENABLED && currentUser) {
      const {id, email} = currentUser;
      // TODO: figure out a better way to initialize this?
      const storytime = Storytime.init({
        accountId: REACT_APP_ADMIN_ACCOUNT_ID,
        baseUrl: BASE_URL,
        debug: isDev,
        customer: {
          email,
          external_id: id,
        },
      });

      return () => storytime.finish();
    }
  }, [currentUser]);

  useEffect(() => {
    let timeout;

    if (totalNumUnread > 0) {
      timeout = setTimeout(toggleNotificationMessage, TITLE_FLASH_INTERVAL);
    } else {
      clearTimeout(timeout);
    }
  });

  return (
    <Layout>
      <Helmet defer={false}>
        <title>{totalNumUnread ? htmlTitle : 'Papercups'}</title>
      </Helmet>

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
              <Menu.SubMenu
                key="account"
                icon={<UserOutlined />}
                title="Account"
              >
                <Menu.Item key="overview">
                  <Link to="/account/overview">Overview</Link>
                </Menu.Item>
                <Menu.Item key="profile">
                  <Link to="/account/profile">My Profile</Link>
                </Menu.Item>
                <Menu.Item key="getting-started">
                  <Link to="/account/getting-started">Getting started</Link>
                </Menu.Item>
              </Menu.SubMenu>
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
                        count={unread.all}
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
                        count={unread.mine}
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
                        count={unread.priority}
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
              <Menu.Item
                title="Customers"
                icon={<TeamOutlined />}
                key="customers"
              >
                <Link to="/customers">Customers</Link>
              </Menu.Item>
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
              {shouldDisplayBilling && (
                <Menu.Item
                  title="Billing"
                  icon={<CreditCardOutlined />}
                  key="billing"
                >
                  <Link to="/billing">Billing</Link>
                </Menu.Item>
              )}
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
          <Route path="/account/overview" component={AccountOverview} />
          <Route path="/account/profile" component={UserProfile} />
          <Route
            path="/account/getting-started"
            component={GettingStartedOverview}
          />
          <Route path="/account*" component={AccountOverview} />
          <Route path="/customers" component={CustomersPage} />
          <Route path="/integrations/:type" component={IntegrationsOverview} />
          <Route path="/integrations" component={IntegrationsOverview} />
          <Route path="/integrations*" component={IntegrationsOverview} />
          <Route path="/conversations/all" component={AllConversations} />
          <Route path="/conversations/me" component={MyConversations} />
          <Route
            path="/conversations/priority"
            component={PriorityConversations}
          />
          <Route path="/conversations/closed" component={ClosedConversations} />
          {shouldDisplayBilling && (
            <Route path="/billing" component={BillingOverview} />
          )}
          <Route path="/reporting" component={ReportingDashboard} />
          <Route path="/sessions/live/:session" component={LiveSessionViewer} />
          <Route path="/sessions/list" component={SessionsOverview} />
          <Route path="/sessions/setup" component={InstallingStorytime} />
          <Route path="/sessions*" component={SessionsOverview} />
          <Route path="*" render={() => <Redirect to="/conversations/all" />} />
        </Switch>
      </Layout>

      {currentUser && (
        <ChatWidget
          title="Need help with anything?"
          subtitle="Ask us in the chat window below 😊"
          greeting="Hi there! Send us a message and we'll get back to you as soon as we can."
          primaryColor="#1890ff"
          accountId="eb504736-0f20-4978-98ff-1a82ae60b266"
          hideToggleButton
          customer={{
            external_id: currentUser.id,
            email: currentUser.email,
          }}
        />
      )}
    </Layout>
  );
};

const DashboardWrapper = (props: RouteComponentProps) => {
  return (
    <ConversationsProvider>
      <Dashboard {...props} />
    </ConversationsProvider>
  );
};

export default DashboardWrapper;
