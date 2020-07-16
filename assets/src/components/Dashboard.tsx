import React from 'react';
import {Switch, Route, Link, RouteComponentProps} from 'react-router-dom';
import {Box, Flex} from 'theme-ui';
import {colors, Layout, Menu, Sider} from './common';
import {MailOutlined, UserOutlined, SettingOutlined} from './icons';
import {useAuth} from './AuthProvider';
import AllConversations from './AllConversations';
import MyConversations from './MyConversations';
import PriorityConversations from './PriorityConversations';
import ClosedConversations from './ClosedConversations';

const Dashboard = (props: RouteComponentProps) => {
  const auth = useAuth();

  const logout = () => {
    auth.logout().then(() => props.history.push('/login'));
  };

  return (
    <Layout>
      <Sider
        width={80}
        collapsed
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
            <Menu defaultSelectedKeys={['all']} mode="inline" theme="dark">
              <Menu.Item key="account" icon={<UserOutlined />}>
                Account
              </Menu.Item>
              <Menu.SubMenu key="inbox" icon={<MailOutlined />} title="Inbox">
                <Menu.Item key="all">
                  <Link to="/conversations/all">All conversations</Link>
                </Menu.Item>
                <Menu.Item key="me">
                  <Link to="/conversations/me">Assigned to me</Link>
                </Menu.Item>
                <Menu.Item key="prioritized">
                  <Link to="/conversations/priority">Prioritized</Link>
                </Menu.Item>
                <Menu.Item key="closed">
                  <Link to="/conversations/closed">Closed</Link>
                </Menu.Item>
              </Menu.SubMenu>
            </Menu>
          </Box>

          <Box py={3}>
            <Menu mode="inline" theme="dark">
              <Menu.SubMenu
                key="settings"
                icon={<SettingOutlined />}
                title="Settings"
              >
                <Menu.Item key="all" onClick={logout}>
                  Log out
                </Menu.Item>
              </Menu.SubMenu>
            </Menu>
          </Box>
        </Flex>
      </Sider>

      <Layout style={{marginLeft: 80, background: colors.white}}>
        <Switch>
          <Route path="/conversations/all" component={AllConversations} />
          <Route path="/conversations/me" component={MyConversations} />
          <Route
            path="/conversations/priority"
            component={PriorityConversations}
          />
          <Route path="/conversations/closed" component={ClosedConversations} />
          <Route path="/conversations*" component={AllConversations} />
        </Switch>
      </Layout>
    </Layout>
  );
};

export default Dashboard;
