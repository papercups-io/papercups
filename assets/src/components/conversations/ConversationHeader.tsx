import React, {Fragment} from 'react';
import {Box, Flex} from 'theme-ui';
import dayjs from 'dayjs';
import utc from 'dayjs/plugin/utc';
import {
  colors,
  Button,
  Popconfirm,
  Drawer,
  Select,
  Text,
  Title,
  Tooltip,
} from '../common';
import {
  CheckOutlined,
  StarOutlined,
  StarFilled,
  UploadOutlined,
  UserOutlined,
} from '../icons';
import {Customer, Conversation, User} from '../../types';
import ConversationDetailsSidebar from './ConversationDetailsSidebar';
import DeleteOutlined from '@ant-design/icons/DeleteOutlined';

// TODO: create date utility methods so we don't have to do this everywhere
dayjs.extend(utc);

const hasCustomerMetadata = (customer: Customer) => {
  const {current_url, browser, os} = customer;

  if (!current_url && !browser && !os) {
    return false;
  }

  return true;
};

const CustomerMetadataSubheader = ({
  customer,
  conversation,
}: {
  customer: Customer;
  conversation: Conversation;
}) => {
  const [isDrawerVisible, setDrawerVisible] = React.useState(false);

  if (!hasCustomerMetadata(customer)) {
    return null;
  }

  const {
    current_url,
    pathname,
    browser,
    os,
    ip,
    time_zone: timezone,
  } = customer;
  const formattedTimezone =
    timezone && timezone.length ? timezone.split('_').join(' ') : null;

  return (
    <>
      <Flex>
        <Flex
          sx={{
            flex: 1,
            overflow: 'hidden',
            whiteSpace: 'nowrap',
          }}
        >
          {current_url && (
            <Box
              pr={3}
              mr={3}
              sx={{
                maxWidth: 240,
                overflow: 'hidden',
                whiteSpace: 'nowrap',
                textOverflow: 'ellipsis',
                borderRight: '1px solid rgba(0,0,0,.06)',
              }}
            >
              <a href={current_url} target="_blank" rel="noopener noreferrer">
                {pathname && pathname.length > 1 ? pathname : current_url}
              </a>
            </Box>
          )}
          {(browser || os) && (
            <Box mr={3}>
              <Text type="secondary">
                {[browser, os, formattedTimezone || ip]
                  .filter(Boolean)
                  .join(' · ')}
              </Text>
            </Box>
          )}
        </Flex>
        <Box>
          <Button size="small" onClick={() => setDrawerVisible(true)}>
            View details
          </Button>
        </Box>
      </Flex>

      <Drawer
        placement="right"
        width={240}
        closable={false}
        bodyStyle={{padding: 0, display: 'flex'}}
        visible={isDrawerVisible}
        onClose={() => setDrawerVisible(false)}
      >
        <ConversationDetailsSidebar
          customer={customer}
          conversation={conversation}
        />
      </Drawer>
    </>
  );
};

const ConversationHeader = ({
  conversation,
  users,
  onAssignUser,
  onMarkPriority,
  onRemovePriority,
  onCloseConversation,
  onReopenConversation,
  onDeleteConversation,
}: {
  conversation: Conversation | null;
  users: Array<User>;
  onAssignUser: (conversationId: string, userId: string) => void;
  onMarkPriority: (conversationId: string) => void;
  onRemovePriority: (conversationId: string) => void;
  onCloseConversation: (conversationId: string) => void;
  onReopenConversation: (conversationId: string) => void;
  onDeleteConversation: (conversationId: string) => void;
}) => {
  if (!conversation) {
    // No point in showing the header if no conversation exists
    return null;
  }
  const {
    id: conversationId,
    assignee_id,
    status,
    priority,
    customer,
  } = conversation;
  const {name, email} = customer;
  const assigneeId = assignee_id ? String(assignee_id) : undefined;
  const hasBothNameAndEmail = !!(name && email);

  return (
    <header
      style={{
        boxShadow: 'rgba(0, 0, 0, 0.1) 0px 0px 2rem',
        zIndex: 1,
        opacity: status === 'closed' ? 0.8 : 1,
      }}
    >
      <Flex
        py={3}
        px={4}
        backgroundColor={colors.white}
        sx={{justifyContent: 'space-between', alignItems: 'center'}}
      >
        <Box>
          <Flex sx={{alignItems: 'center'}}>
            <Title
              level={4}
              style={{
                marginBottom: hasBothNameAndEmail ? 0 : 4,
                marginTop: hasBothNameAndEmail ? 0 : 4,
              }}
            >
              {name || email || 'Anonymous User'}
            </Title>
          </Flex>
          {hasBothNameAndEmail && (
            <Box style={{marginLeft: 1, lineHeight: 1.2}}>
              <Text type="secondary">{email}</Text>
            </Box>
          )}
        </Box>

        <Flex mx={-1}>
          <Box mx={1}>
            <Select
              style={{minWidth: 240}}
              placeholder="No assignee"
              value={assigneeId ? String(assigneeId) : undefined}
              onSelect={(userId) =>
                onAssignUser(conversationId, String(userId))
              }
            >
              {users.map((user: User) => {
                const value = String(user.id);

                return (
                  <Select.Option key={value} value={value}>
                    <Flex sx={{alignItems: 'center'}}>
                      <UserOutlined style={{marginRight: 8, fontSize: 12}} />
                      <Box>{user.full_name || user.email}</Box>
                    </Flex>
                  </Select.Option>
                );
              })}
            </Select>
          </Box>
          <Box mx={1}>
            {priority === 'priority' ? (
              <Tooltip title="Remove priority" placement="bottomRight">
                <Button
                  icon={<StarFilled style={{color: colors.gold}} />}
                  onClick={() => onRemovePriority(conversationId)}
                />
              </Tooltip>
            ) : (
              <Tooltip title="Mark as priority" placement="bottomRight">
                <Button
                  icon={<StarOutlined />}
                  onClick={() => onMarkPriority(conversationId)}
                />
              </Tooltip>
            )}
          </Box>

          {status === 'closed' ? (
            <Fragment>
              <Box mx={1}>
                <Tooltip title="Reopen conversation" placement="bottomRight">
                  <Button
                    icon={<UploadOutlined />}
                    onClick={() => onReopenConversation(conversationId)}
                  />
                </Tooltip>
              </Box>
              <Box mx={1}>
                <Popconfirm
                  title="Are you sure you want to delete this conversation?"
                  okText="Yes"
                  cancelText="No"
                  placement="leftBottom"
                  onConfirm={() => onDeleteConversation(conversationId)}
                >
                  <Tooltip title="Delete conversation" placement="bottomRight">
                    <Button icon={<DeleteOutlined />} />
                  </Tooltip>
                </Popconfirm>
              </Box>
            </Fragment>
          ) : (
            <Box mx={1}>
              <Tooltip title="Close conversation" placement="bottomRight">
                <Button
                  icon={<CheckOutlined />}
                  onClick={() => onCloseConversation(conversationId)}
                />
              </Tooltip>
            </Box>
          )}
        </Flex>
      </Flex>

      {/* NB: just hiding this for now */}
      {false && hasCustomerMetadata(customer) && (
        <Box
          py={2}
          mx={4}
          sx={{
            justifyContent: 'space-between',
            alignItems: 'center',
            borderTop: '1px solid rgba(0,0,0,.06)',
          }}
        >
          <CustomerMetadataSubheader
            customer={customer}
            conversation={conversation as Conversation}
          />
        </Box>
      )}
    </header>
  );
};

export default ConversationHeader;
