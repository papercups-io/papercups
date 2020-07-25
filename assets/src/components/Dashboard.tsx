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
import {colors, Layout, Menu, Sider} from './common';
import {
  ApiOutlined,
  MailOutlined,
  UserOutlined,
  SettingOutlined,
} from './icons';
import {useAuth} from './auth/AuthProvider';
import AccountOverview from './account/AccountOverview';
import GettingStartedOverview from './account/GettingStartedOverview';
import AllConversations from './conversations/AllConversations';
import MyConversations from './conversations/MyConversations';
import PriorityConversations from './conversations/PriorityConversations';
import ClosedConversations from './conversations/ClosedConversations';
import IntegrationsOverview from './integrations/IntegrationsOverview';

const Dashboard = (props: RouteComponentProps) => {
  const auth = useAuth();
  const location = useLocation();
  const [section, key] = location.pathname.split('/').slice(1); // Slice off initial slash

  const logout = () => {
    auth.logout().then(() => props.history.push('/login'));
  };

  return (
    <Layout>
      <Sider
        width={200}
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
                  <Link to="/conversations/all">All conversations</Link>
                </Menu.Item>
                <Menu.Item key="me">
                  <Link to="/conversations/me">Assigned to me</Link>
                </Menu.Item>
                <Menu.Item key="priority">
                  <Link to="/conversations/priority">Prioritized</Link>
                </Menu.Item>
                <Menu.Item key="closed">
                  <Link to="/conversations/closed">Closed</Link>
                </Menu.Item>
              </Menu.SubMenu>
              <Menu.Item
                title="Integrations"
                icon={<ApiOutlined />}
                key="integrations"
              >
                <Link to="/integrations">Integrations</Link>
              </Menu.Item>
            </Menu>
          </Box>

          <Box py={3}>
            <Menu mode="inline" theme="dark">
              <Menu.Item
                title="Log out"
                icon={<SettingOutlined />}
                key="logout"
                onClick={logout}
              >
                Log out
              </Menu.Item>
            </Menu>
          </Box>
        </Flex>
      </Sider>

      <Layout style={{marginLeft: 200, background: colors.white}}>
        <Switch>
          <Route path="/account/overview" component={AccountOverview} />
          <Route
            path="/account/getting-started"
            component={GettingStartedOverview}
          />
          <Route path="/account*" component={AccountOverview} />
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
          <Route path="/conversations*" component={AllConversations} />
          <Route path="*" render={() => <Redirect to="/conversations/all" />} />
        </Switch>
      </Layout>
    </Layout>
  );
};

export default Dashboard;
