import React from 'react';
import {WindowsOutlined} from '@ant-design/icons';
import {List} from 'antd';

const isMac = navigator.platform.toUpperCase().indexOf('MAC') >= 0;

const ShortCutModal = () => {
  if (isMac) {
    return (
      <List>
        <List.Item>
          <b>⌘ Enter</b> - Send a message
        </List.Item>
        <List.Item>
          <b>⌘ d </b> - Close a conversation
        </List.Item>
        <List.Item>
          <b>⌘ ↑ </b> - Next conversation
        </List.Item>
        <List.Item>
          <b>⌘ ↓ </b>- Previous conversation
        </List.Item>
        <List.Item>
          <b>⌘ p </b> - Mark as prioritize
        </List.Item>
        <List.Item>
          <b>Esc </b>- Close window/modal
        </List.Item>
      </List>
    );
  }
  return (
    <List>
      <List.Item>
        <b>
          <WindowsOutlined /> Win Enter
        </b>{' '}
        - Send a message
      </List.Item>
      <List.Item>
        <b>
          <WindowsOutlined /> d
        </b>{' '}
        - Close a conversation
      </List.Item>
      <List.Item>
        <b>
          <WindowsOutlined /> ↑
        </b>{' '}
        - Next conversation
      </List.Item>
      <List.Item>
        <b>
          <WindowsOutlined /> ↓{' '}
        </b>
        - Previous conversation
      </List.Item>
      <List.Item>
        <b>
          <WindowsOutlined /> p{' '}
        </b>{' '}
        - Mark as prioritize
      </List.Item>
      <List.Item>
        <b>Esc </b> - Close window/modal
      </List.Item>
    </List>
  );
};

export default ShortCutModal;
