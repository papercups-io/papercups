import React from 'react';
import {Box, Flex} from 'theme-ui';
import {Button, List, Modal, Text} from '../common';
import {WindowsOutlined} from '../icons';

const DashboardShortcutsModal = ({
  visible,
  onCancel,
}: {
  visible: boolean;
  onCancel: () => void;
}) => {
  const isMac = navigator.platform.toLowerCase().indexOf('mac') !== -1;
  const shortcuts = [
    {
      mac: '⌘ Enter',
      windows: (
        <Text>
          <WindowsOutlined /> Enter
        </Text>
      ),
      description: 'Send a message',
    },
    {
      mac: '⌘ D',
      windows: (
        <Text>
          <WindowsOutlined /> D
        </Text>
      ),
      description: 'Close a conversation',
    },
    {
      mac: '⌘ ↑',
      windows: (
        <Text>
          <WindowsOutlined /> ↑
        </Text>
      ),
      description: 'Next conversation',
    },
    {
      mac: '⌘ ↓',
      windows: (
        <Text>
          <WindowsOutlined /> ↓
        </Text>
      ),
      description: 'Previous conversation',
    },
    {
      mac: '⌘ P',
      windows: (
        <Text>
          <WindowsOutlined /> P
        </Text>
      ),
      description: 'Mark conversation as priority',
    },
    {
      mac: 'Esc',
      windows: (
        <Text>
          <WindowsOutlined /> Esc
        </Text>
      ),
      description: 'Close window/modal',
    },
  ];

  return (
    <Modal
      title="Keyboard Shortcuts"
      visible={visible}
      onCancel={onCancel}
      footer={[
        <Button key="cancel" onClick={onCancel}>
          Done
        </Button>,
      ]}
    >
      <List>
        {shortcuts.map(({mac, windows, description}) => {
          const key = isMac ? mac : windows;

          return (
            <List.Item key={description}>
              <Flex sx={{alignItems: 'center'}}>
                <Box mr={1}>
                  <Text strong>{key}</Text>
                </Box>
                <Box>
                  <Text type="secondary">&mdash; {description}</Text>
                </Box>
              </Flex>
            </List.Item>
          );
        })}
      </List>
    </Modal>
  );
};

export const DashboardShortcutsRenderer = ({
  children,
}: {
  children: (handleOpenModal: () => void) => React.ReactElement;
}) => {
  const [isModalOpen, setModalOpen] = React.useState(false);

  const handleOpenModal = () => setModalOpen(true);
  const handleCloseModal = () => setModalOpen(false);

  return (
    <React.Fragment>
      {children(handleOpenModal)}

      <DashboardShortcutsModal
        visible={isModalOpen}
        onCancel={handleCloseModal}
      />
    </React.Fragment>
  );
};
