import React from 'react';
import {Box, Flex} from 'theme-ui';
import {colors, Button, Select, Title, Tooltip} from './common';
import {
  CheckOutlined,
  StarOutlined,
  StarFilled,
  UploadOutlined,
  UserOutlined,
} from './icons';

const ConversationHeader = ({
  conversation,
  users,
  onAssignUser,
  onMarkPriority,
  onRemovePriority,
  onCloseConversation,
  onReopenConversation,
}: {
  conversation: any;
  users: Array<any>;
  onAssignUser: (conversationId: string, userId: string) => void;
  onMarkPriority: (conversationId: string) => void;
  onRemovePriority: (conversationId: string) => void;
  onCloseConversation: (conversationId: string) => void;
  onReopenConversation: (conversationId: string) => void;
}) => {
  if (!conversation) {
    return (
      <header
        style={{
          boxShadow: 'rgba(0, 0, 0, 0.1) 0px 0px 2rem',
          zIndex: 1,
          opacity: 0.8,
          minHeight: 68,
        }}
      >
        <Flex
          py={3}
          px={4}
          backgroundColor={colors.white}
          sx={{justifyContent: 'space-between', alignItems: 'baseline'}}
        >
          <Title level={4} style={{marginBottom: 0, marginTop: 4}}>
            &nbsp;
          </Title>
        </Flex>
      </header>
    );
  }

  const {
    id: conversationId,
    assignee_id: assigneeId,
    status,
    priority,
  } = conversation;

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
        sx={{justifyContent: 'space-between', alignItems: 'baseline'}}
      >
        <Title level={4} style={{marginBottom: 0, marginTop: 4}}>
          Anonymous User
        </Title>

        <Flex mx={-1}>
          <Box mx={1}>
            <Select
              style={{minWidth: 240}}
              placeholder="No assignee"
              value={assigneeId}
              onChange={(...args) => console.log('Changed!', args)}
              onSelect={(userId) =>
                onAssignUser(conversationId, String(userId))
              }
            >
              {users.map((user: any) => {
                return (
                  <Select.Option key={user.id} value={user.id}>
                    <Flex sx={{alignItems: 'center'}}>
                      <UserOutlined style={{marginRight: 8, fontSize: 12}} />
                      <Box>{user.name || user.email}</Box>
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

          <Box mx={1}>
            {status === 'closed' ? (
              <Tooltip title="Reopen conversation" placement="bottomRight">
                <Button
                  icon={<UploadOutlined />}
                  onClick={() => onReopenConversation(conversationId)}
                />
              </Tooltip>
            ) : (
              <Tooltip title="Close conversation" placement="bottomRight">
                <Button
                  icon={<CheckOutlined />}
                  onClick={() => onCloseConversation(conversationId)}
                />
              </Tooltip>
            )}
          </Box>
        </Flex>
      </Flex>
    </header>
  );
};

export default ConversationHeader;
