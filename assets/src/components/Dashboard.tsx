import React from 'react';
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
import {colors, Badge, Layout, Menu, Sider} from './common';
import {
  ApiOutlined,
  MailOutlined,
  UserOutlined,
  LogoutOutlined,
  CreditCardOutlined,
  TeamOutlined,
} from './icons';
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

const hasValidStripeKey = () => {
  const key = process.env.REACT_APP_STRIPE_PUBLIC_KEY;

  return key && key.startsWith('pk_');
};

const Dashboard = (props: RouteComponentProps) => {
  const auth = useAuth();
  const {pathname} = useLocation();
  const {unreadByCategory: unread} = useConversations();
  const [section, key] = pathname.split('/').slice(1); // Slice off initial slash
  const totalNumUnread = (unread && unread.all) || 0;
  const shouldDisplayBilling = hasValidStripeKey();

  const logout = () => auth.logout().then(() => props.history.push('/login'));

  return (
    <Layout>
      <Helmet>
        <title>
          {totalNumUnread
            ? `(${totalNumUnread}) New message${
                totalNumUnread === 1 ? '' : 's'
              }!`
            : 'Papercups'}
        </title>
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
              defaultOpenKeys={[section, 'account', 'conversations']}
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
              <Menu.Item
                title="Customers"
                icon={<TeamOutlined />}
                key="customers"
              >
                <Link to="/customers">Customers</Link>
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
            <Menu mode="inline" theme="dark">
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
          <Route path="*" render={() => <Redirect to="/conversations/all" />} />
        </Switch>
      </Layout>
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
