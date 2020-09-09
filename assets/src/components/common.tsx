import Alert from 'antd/lib/alert';
import Badge from 'antd/lib/badge';
import Button from 'antd/lib/button';
import Checkbox from 'antd/lib/checkbox';
import DatePicker from 'antd/lib/date-picker';
import Divider from 'antd/lib/divider';
import Drawer from 'antd/lib/drawer';
import Dropdown from 'antd/lib/dropdown';
import Input from 'antd/lib/input';
import Layout from 'antd/lib/layout';
import Menu from 'antd/lib/menu';
import Modal from 'antd/lib/modal';
import notification from 'antd/lib/notification';
import Popconfirm from 'antd/lib/popconfirm';
import Popover from 'antd/lib/popover';
import Radio from 'antd/lib/radio';
import Result from 'antd/lib/result';
import Select from 'antd/lib/select';
import Spin from 'antd/lib/spin';
import Table from 'antd/lib/table';
import Tag from 'antd/lib/tag';
import Tooltip from 'antd/lib/tooltip';
import Typography from 'antd/lib/typography';

import {
  blue,
  green,
  red,
  volcano,
  orange,
  gold,
  purple,
  magenta,
  grey,
} from '@ant-design/colors';

const {Title, Text, Paragraph} = Typography;
const {Header, Content, Footer, Sider} = Layout;

export const colors = {
  white: '#fff',
  black: '#000',
  primary: blue[5],
  green: green[5],
  red: red[5],
  gold: gold[5],
  volcano: volcano[5],
  orange: orange[5],
  purple: purple[5],
  magenta: magenta[5],
  blue: blue, // expose all blues
  gray: grey, // expose all grays
  text: 'rgba(0, 0, 0, 0.65)',
};

export const TextArea = Input.TextArea;

/* Whitelist node types that we allow when we render markdown.
 * Reference https://github.com/rexxars/react-markdown#node-types
 */
export const allowedNodeTypes: any[] = [
  'root',
  'text',
  'break',
  'paragraph',
  'emphasis',
  'strong',
  'blockquote',
  'delete',
  'link',
  'linkReference',
  'list',
  'listItem',
  'heading',
  'inlineCode',
  'code',
];

export {
  // Typography
  Title,
  Text,
  Paragraph,
  // Layout
  Content,
  Footer,
  Layout,
  Header,
  Sider,
  // Components
  Alert,
  Badge,
  Button,
  Checkbox,
  DatePicker,
  Divider,
  Drawer,
  Dropdown,
  Input,
  Menu,
  Modal,
  notification,
  Popconfirm,
  Popover,
  Radio,
  Result,
  Select,
  Spin,
  Table,
  Tag,
  Tooltip,
};
