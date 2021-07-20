type Theme = {color?: string; iconUrl?: string};

export const getDefaultCss = (theme: Theme = {}) => `
#PreviewPapercupsModal .ic_message_content h1,
#PreviewPapercupsModal .ic_message_content h2 {
  color: #0072b0 !important;
}
#PreviewPapercupsModal
  .ic_message_without_image
  > .ic_message_internals
  > .ic_message_content {
  border-color: #0072b0 !important;
}
#PreviewPapercupsModal .ic_user_comment_body {
  background-color: #0072b0 !important;
  border-color: #0072b0 !important;
}
#PreviewPapercupsModal .ic_message_content a {
  color: #0072b0 !important;
}
#PreviewPapercupsModal .ic_message_content a:hover {
  color: #0072b0 !important;
}
#PreviewPapercupsModal .ic_user_comment_body {
  background-color: #0072b0 !important;
  border-color: #0072b0 !important;
}
.papercups-h2b-button br {
  display: none;
}

.admin_name b {
  color: #6f6f6f;
}

.date_cell a {
  color: #999999;
}

.comment_header_td {
  width: 100%;
  background: ${theme.color || 'rgb(155, 48, 247)'};
  border: none;
  font-family: 'Helvetica Neue', Arial, sans-serif;
}

.content-td {
  color: #525252;
  font-family: Helvetica, Arial, sans-serif;
}

.content-td h1 {
  font-size: 26px;
  line-height: 33px;
  color: #282f33;
  margin-bottom: 7px;
  margin-top: 30px;
  font-weight: normal;
}

.content-td h1 a {
  color: #282f33;
}

.content-td h2 {
  font-size: 18px;
  font-weight: bold;
  color: #282f33;
  margin: 30px 0 7px;
}

.content-td h2 a {
  color: #282f33;
}

.content-td h1 + h2 {
  margin-top: 0 !important;
}

.content-td h2 + h1 {
  margin-top: 0 !important;
}

.content-td h3,
.content-td h4,
.content-td h5 {
  font-size: 16px;
  font-weight: bold;
  margin-bottom: 5px;
}

.content-td p {
  margin: 0 0 17px 0;
  line-height: 1.5;
}

.content-td p img,
.content-td h1 img,
.content-td h2 img,
.content-td li img,
.content-td .papercups-h2b-button img {
  margin: 0;
  padding: 0;
}

.content-td a {
  color: #1251ba;
}

.content-td p.intro {
  font-size: 20px;
  line-height: 30px;
}

.content-td blockquote {
  margin: 40px 0;
  font-style: italic;
  color: #8c8c8c;
  font-size: 18px;
  text-align: center;
  padding: 0 30px;
  font-family: Georgia, sans-serif;
  quotes: none;
}

.content-td blockquote a {
  color: #8c8c8c;
}

.content-td ul {
  list-style: disc;
  margin: 0 0 20px 40px;
  padding: 0;
}

.content-td ol {
  list-style: decimal;
  margin: 0 0 20px 40px;
  padding: 0;
}

.content-td img {
  margin: 0;
  max-width: 100%;
}

.content-td .papercups-container {
  margin-bottom: 16px;
}

.content-td div.papercups-container {
  margin-bottom: 17px;
  margin-top: 17px;
  line-height: 0;
}

.content-td hr {
  border: none;
  border-top: 1px solid #ddd;
  border-bottom: 0;
  margin: 50px 30% 50px 30%;
}

/**/
.content-td pre {
  margin: 0 0 10px;
  padding: 10px;
  background-color: #f5f5f5;
  overflow: auto;
}

.content-td pre code {
  font-family: Courier, monospace;
  font-size: 14px;
  line-height: 1.4;
  white-space: nowrap;
}

table.papercups-container {
  margin: 17px 0;
}
table.papercups-container.papercups-align-center {
  margin-left: auto;
  margin-right: auto;
}

table.papercups-container td {
  background-color: ${theme.color || 'rgb(155, 48, 247)'};
  padding: 12px 35px;
  border-radius: 3px;
  font-family: Helvetica, Arial, sans-serif;
  margin: 0;
}

.content-td .papercups-h2b-button {
  font-size: 14px;
  color: #fff;
  font-weight: bold;
  display: inline-block;
  text-decoration: none;
  background-color: ${theme.color || 'rgb(155, 48, 247)'};
  border: none !important;

  padding: 13px 35px;
}

a.papercups-h2b-button {
  background-color: ${theme.color || 'rgb(155, 48, 247)'};
  border-radius: 5px;
  border: 1px solid rgba(0, 0, 0, 0.2);
  color: #fff;
  display: inline-block;
  font-size: 15px;
  font-weight: bold;
  min-height: 20px;
  text-decoration: none;
}

.content-td .papercups-h2b-button:hover {
  background-color: ${theme.color || 'rgb(155, 48, 247)'};
}

.message_footer_table .avatar {
  -ms-interpolation-mode: bicubic;
  -webkit-background-clip: padding-box;
  -webkit-border-radius: 20px;
  background-clip: padding-box;
  border-radius: 20px;
  display: inline-block;
  height: 40px;
  max-width: 100%;
  outline: none;
  text-decoration: none;
  width: 40px;
}

.powered-by-table .powered-by-text a {
  font-weight: bold;
  text-decoration: none;
  color: #999;
}

.main_wrapper {
  padding: 0 20px;
}

.margin-arrow {
  display: none;

  visibility: hidden;
  width: 0;
  height: 0;
  max-width: 0;
  max-height: 0;
  overflow: hidden;
  opacity: 0;
}

.content-td > :first-child {
  margin-top: 0;
  padding-top: 0;
}

table.papercups-container td > a.papercups-h2b-button {
  padding: 0px;
}

.papercups-align-right {
  text-align: right !important;
}
.papercups-align-center {
  text-align: center !important;
}
.papercups-align-left {
  text-align: left !important;
}
/* Over-ride for RTL */
.right-to-left .papercups-align-right {
  text-align: left !important;
}
.right-to-left .papercups-align-left {
  text-align: right !important;
}
.right-to-left .papercups-align-left {
  text-align: right !important;
}
.right-to-left li {
  text-align: right !important;
  direction: rtl;
}
.right-to-left .papercups-align-left img,
.right-to-left .papercups-align-left .papercups-h2b-button {
  margin-left: 0 !important;
}
.papercups-attachment,
.papercups-attachments,
.papercups-attachments td,
.papercups-attachments th,
.papercups-attachments tr,
.papercups-attachments tbody,
.papercups-attachments .icon,
.papercups-attachments .icon img {
  border: none !important;
  box-shadow: none !important;
  padding: 0 !important;
  margin: 0 !important;
}
.papercups-attachments {
  margin: 10px 0 !important;
}
.papercups-attachments .icon,
.papercups-attachments .icon img {
  width: 16px !important;
  height: 16px !important;
}
.papercups-attachments .icon {
  padding-right: 5px !important;
}
.papercups-attachment {
  display: inline-block !important;
  margin-bottom: 5px !important;
}

.papercups-interblocks-content-card {
  width: 334px !important;
  max-height: 136px !important;
  max-width: 100% !important;
  overflow: hidden !important;
  border-radius: 20px !important;
  font-size: 16px !important;
  border: 1px solid #e0e0e0 !important;
}

.papercups-interblocks-link,
.papercups-interblocks-article-card {
  text-decoration: none !important;
}

.papercups-interblocks-article-icon {
  width: 22.5% !important;
  height: 136px !important;
  float: left !important;
  background-color: #fafafa !important;
  background-image: url('${theme.iconUrl}') !important;
  background-repeat: no-repeat !important;
  background-size: 32px !important;
  background-position: center !important;
}

.papercups-interblocks-article-text {
  width: 77.5% !important;
  float: right !important;
  background-color: #fff !important;
}

.papercups-interblocks-link-title,
.papercups-interblocks-article-title {
  color: #519dd4 !important;
  font-size: 15px !important;
  margin: 16px 18px 12px !important;
  line-height: 1.3em !important;
  overflow: hidden !important;
}

.papercups-interblocks-link-description,
.papercups-interblocks-article-body {
  margin: 0 18px 12px !important;
  font-size: 14px !important;
  color: #65757c !important;
  line-height: 1.3em !important;
}

.papercups-interblocks-link-author,
.papercups-interblocks-article-author {
  margin: 10px 15px !important;
  height: 24px !important;
  line-height: normal !important;
}

.papercups-interblocks-link-author-avatar,
.papercups-interblocks-article-author-avatar {
  width: 16px !important;
  height: 16px !important;
  display: inline-block !important;
  vertical-align: middle !important;
  float: left;
  margin-right: 5px;
}

.papercups-interblocks-link-author-avatar-image,
.papercups-interblocks-article-author-avatar-image {
  width: 16px !important;
  height: 16px !important;
  border-radius: 50% !important;
  margin: 0 !important;
  vertical-align: top !important;
  font-size: 12px !important;
}

* img[src*='googleusercontent.com'][alt='papercupsavatar'] {
  display: none !important;
}

.papercups-align-right {
  text-align: right !important;
}
.papercups-align-center {
  text-align: center !important;
}
.papercups-align-left {
  text-align: left !important;
}
/* Over-ride for RTL */
.right-to-left .papercups-align-right {
  text-align: left !important;
}
.right-to-left .papercups-align-left {
  text-align: right !important;
}
.right-to-left .papercups-align-left {
  text-align: right !important;
}
.right-to-left li {
  text-align: right !important;
  direction: rtl;
}
.right-to-left .papercups-align-left img,
.right-to-left .papercups-align-left .papercups-h2b-button {
  margin-left: 0 !important;
}
.papercups-attachment,
.papercups-attachments,
.papercups-attachments td,
.papercups-attachments th,
.papercups-attachments tr,
.papercups-attachments tbody,
.papercups-attachments .icon,
.papercups-attachments .icon img {
  border: none !important;
  box-shadow: none !important;
  padding: 0 !important;
  margin: 0 !important;
}
.papercups-attachments {
  margin: 10px 0 !important;
}
.papercups-attachments .icon,
.papercups-attachments .icon img {
  width: 16px !important;
  height: 16px !important;
}
.papercups-attachments .icon {
  padding-right: 5px !important;
}
.papercups-attachment {
  display: inline-block !important;
  margin-bottom: 5px !important;
}

.papercups-interblocks-content-card {
  width: 334px !important;
  max-height: 136px !important;
  max-width: 100% !important;
  overflow: hidden !important;
  border-radius: 20px !important;
  font-size: 16px !important;
  border: 1px solid #e0e0e0 !important;
}

.papercups-interblocks-link,
.papercups-interblocks-article-card {
  text-decoration: none !important;
}

.papercups-interblocks-article-icon {
  width: 22.5% !important;
  height: 136px !important;
  float: left !important;
  background-color: #fafafa !important;
  background-image: url('${theme.iconUrl}') !important;
  background-repeat: no-repeat !important;
  background-size: 32px !important;
  background-position: center !important;
}

.papercups-interblocks-article-text {
  width: 77.5% !important;
  float: right !important;
  background-color: #fff !important;
}

.papercups-interblocks-link-title,
.papercups-interblocks-article-title {
  color: #519dd4 !important;
  font-size: 15px !important;
  margin: 16px 18px 12px !important;
  line-height: 1.3em !important;
  overflow: hidden !important;
}

.papercups-interblocks-link-description,
.papercups-interblocks-article-body {
  margin: 0 18px 12px !important;
  font-size: 14px !important;
  color: #65757c !important;
  line-height: 1.3em !important;
}

.papercups-interblocks-link-author,
.papercups-interblocks-article-author {
  margin: 10px 15px !important;
  height: 24px !important;
  line-height: normal !important;
}

.papercups-interblocks-link-author-avatar,
.papercups-interblocks-article-author-avatar {
  width: 16px !important;
  height: 16px !important;
  display: inline-block !important;
  vertical-align: middle !important;
  float: left;
  margin-right: 5px;
}

.papercups-interblocks-link-author-avatar-image,
.papercups-interblocks-article-author-avatar-image {
  width: 16px !important;
  height: 16px !important;
  border-radius: 50% !important;
  margin: 0 !important;
  vertical-align: top !important;
  font-size: 12px !important;
}

.papercups-interblocks-link-author-name,
.papercups-interblocks-article-author-name {
  color: #74848b !important;
  margin: 0 0 0 5px !important;
  font-size: 12px !important;
  font-weight: 500 !important;
  overflow: hidden !important;
}

.papercups-interblocks-article-written-by {
  color: #8897a4 !important;
  margin: 1px 0 0 5px !important;
  font-size: 12px !important;
  overflow: hidden !important;
  vertical-align: middle !important;
  float: left !important;
}
`;

export const getPremailerIgnoredCss = () => `
/* styles in here will not be inlined. Use for media queries etc */
/* force Outlook to provide a "view in browser" menu link. */
#outlook a {
  padding: 0;
}
/* prevent Webkit and Windows Mobile platforms from changing default font sizes.*/
body {
  width: 100% !important;
  -webkit-text-size-adjust: 100%;
  -ms-text-size-adjust: 100%;
  margin: 0;
  padding: 0;
}
/* force Hotmail to display emails at full width */
.ExternalClass {
  width: 100%;
}
/* force Hotmail to display normal line spacing. http://www.emailonacid.com/forum/viewthread/43/ */
.ExternalClass,
.ExternalClass p,
.ExternalClass span,
.ExternalClass font,
.ExternalClass td,
.ExternalClass div {
  line-height: 100%;
}
/* fix a padding issue on Outlook 07, 10 */
table td {
  border-collapse: collapse;
}
table {
  table-layout: fixed;
}

@media only screen and (max-width: 480px) {
  br.hidden {
    display: block !important;
  }
  td.padding_cell {
    display: none !important;
  }
  table.message_footer_table td {
    font-size: 11px !important;
  }
}
@media only screen and (max-device-width: 480px) {
  br.hidden {
    display: block !important;
  }
  td.padding_cell {
    display: none !important;
  }
  table.message_footer_table td {
    font-size: 11px !important;
  }
}

/* styles in here will not be inlined. Use for media queries etc */
/* force Outlook to provide a "view in browser" menu link. */
#outlook a {
  padding: 0;
}
/* prevent Webkit and Windows Mobile platforms from changing default font sizes.*/
body {
  width: 100% !important;
  -webkit-text-size-adjust: 100%;
  -ms-text-size-adjust: 100%;
  margin: 0;
  padding: 0;
}
/* force Hotmail to display emails at full width */
.ExternalClass {
  width: 100%;
}
/* force Hotmail to display normal line spacing. http://www.emailonacid.com/forum/viewthread/43/ */
.ExternalClass,
.ExternalClass p,
.ExternalClass span,
.ExternalClass font,
.ExternalClass td,
.ExternalClass div {
  line-height: 100%;
}
/* fix a padding issue on Outlook 07, 10 */
table td {
  border-collapse: collapse;
}

@media only screen and (max-width: 480px) {
  br.hidden {
    display: block !important;
  }
  td.padding_cell {
    display: none !important;
  }
  table.message_footer_table td {
    font-size: 11px !important;
  }
}
@media only screen and (max-device-width: 480px) {
  br.hidden {
    display: block !important;
  }
  td.padding_cell {
    display: none !important;
  }
  table.message_footer_table td {
    font-size: 11px !important;
  }
}

/* Responsive */

@media screen and (max-width: 635px) {
  .main-wrap {
    width: 100% !important;
  }
}

@media screen and (max-width: 480px) {
  .content-td {
    padding: 30px 15px !important;
  }
  .content-td h1 {
    margin-bottom: 5px;
  }
  .message_footer_table .space {
    width: 20px !important;
  }

  .message_footer_table .arrow-wrap {
    padding-left: 20px !important;
  }

  .message_footer_table .admin_name b {
    display: block !important;
  }

  .main_wrapper {
    padding: 0;
  }

  .image-arrow {
    display: none !important;
  }

  .margin-arrow {
    display: table !important;
    visibility: visible !important;
    width: 100% !important;
    height: auto !important;
    max-width: none !important;
    max-height: none !important;
    opacity: 1 !important;
    overflow: visible !important;
  }

  .comment_body {
    border-bottom: 1px solid #ddd !important;
  }

  .footer-td-wrapper {
    display: block !important;
    width: 100% !important;
    text-align: left !important;
  }
  .footer-td-wrapper .date_cell {
    text-align: left !important;
    padding: 15px 0 0 20px !important;
  }
}

.content-td blockquote + * {
  margin-top: 20px !important;
}

.ExternalClass .content-td h1 {
  padding: 20px 0 !important;
}

.ExternalClass .content-td h2 {
  padding: 0 0 5px !important;
}

.ExternalClass .content-td p {
  padding: 10px 0 !important;
}

.ExternalClass .content-td .papercups-container {
  padding: 5px 0 !important;
}

.ExternalClass .content-td hr + * {
  padding-top: 30px !important;
}

.ExternalClass .content-td ol,
.ExternalClass .content-td ul {
  padding: 0 0 20px 40px !important;
  margin: 0 !important;
}

.ExternalClass .content-td ol li,
.ExternalClass .content-td ul li {
  padding: 3px 0 !important;
  margin: 0 !important;
}
.content-td > :first-child {
  margin-top: 0 !important;
  padding-top: 0 !important;
}

.ExternalClass .content-td > :first-child {
  margin-top: 0 !important;
  padding-top: 0 !important;
}
`;
