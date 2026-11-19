using System;
using System.Collections.Generic;
using System.Drawing;
using System.Windows.Forms;

namespace AngelaMihomo.LoopbackManager
{
    /// <summary>
    /// Single-window interface: a checkable list of every app container on
    /// the machine. Ticked rows are the ones allowed to use the loopback
    /// address; Save writes the whole selection back at once.
    /// </summary>
    internal sealed class MainForm : Form
    {
        private readonly ListView _list;
        private readonly Label _status;
        private readonly Button _saveButton;

        public MainForm()
        {
            Text = Strings.AppTitle;
            ClientSize = new Size(760, 520);
            MinimumSize = new Size(560, 360);
            StartPosition = FormStartPosition.CenterScreen;

            Label intro = new Label();
            intro.Text = Strings.IntroText;
            intro.Dock = DockStyle.Top;
            intro.AutoSize = false;
            intro.Height = 32;
            intro.Padding = new Padding(10, 8, 10, 0);
            Controls.Add(intro);

            _list = new ListView();
            _list.Dock = DockStyle.Fill;
            _list.View = View.Details;
            _list.CheckBoxes = true;
            _list.FullRowSelect = true;
            _list.HideSelection = false;
            _list.Columns.Add(Strings.ColumnApp, 240);
            _list.Columns.Add(Strings.ColumnPackage, 340);
            _list.Columns.Add(Strings.ColumnStatus, 110);
            _list.ItemChecked += OnItemChecked;
            Controls.Add(_list);

            Panel buttons = new Panel();
            buttons.Dock = DockStyle.Bottom;
            buttons.Height = 44;
            Controls.Add(buttons);

            Button refreshButton = new Button();
            refreshButton.Text = Strings.RefreshButton;
            refreshButton.Location = new Point(10, 9);
            refreshButton.Click += delegate { Reload(); };
            buttons.Controls.Add(refreshButton);

            _saveButton = new Button();
            _saveButton.Text = Strings.SaveButton;
            _saveButton.Location = new Point(95, 9);
            _saveButton.Click += OnSave;
            buttons.Controls.Add(_saveButton);

            Button closeButton = new Button();
            closeButton.Text = Strings.CloseButton;
            closeButton.Location = new Point(180, 9);
            closeButton.Click += delegate { Close(); };
            buttons.Controls.Add(closeButton);

            _status = new Label();
            _status.Location = new Point(275, 14);
            _status.AutoSize = true;
            buttons.Controls.Add(_status);

            // Docking order: the fill control must be added last to sit
            // between the top intro and the bottom button bar.
            Controls.SetChildIndex(_list, 0);
            Load += delegate { Reload(); };
        }

        private void Reload()
        {
            try
            {
                List<AppContainerInfo> containers = Loopback.ListContainers();
                _list.BeginUpdate();
                _list.Items.Clear();
                foreach (AppContainerInfo info in containers)
                {
                    ListViewItem item = new ListViewItem(DisplayText(info));
                    item.SubItems.Add(info.Name);
                    item.SubItems.Add(
                        info.LoopbackExempt ? Strings.StatusExempt : Strings.StatusBlocked);
                    item.Tag = info;
                    item.Checked = info.LoopbackExempt;
                    _list.Items.Add(item);
                }
                _list.EndUpdate();
                _status.Text = Strings.LoadedMessage(containers.Count);
            }
            catch (Exception ex)
            {
                ShowError(ex);
            }
        }

        private void OnItemChecked(object sender, ItemCheckedEventArgs e)
        {
            AppContainerInfo info = e.Item.Tag as AppContainerInfo;
            if (info == null || e.Item.SubItems.Count < 3)
            {
                return;
            }
            e.Item.SubItems[2].Text =
                e.Item.Checked ? Strings.StatusExempt : Strings.StatusBlocked;
        }

        private void OnSave(object sender, EventArgs e)
        {
            List<string> desired = new List<string>();
            foreach (ListViewItem item in _list.Items)
            {
                if (!item.Checked)
                {
                    continue;
                }
                AppContainerInfo info = item.Tag as AppContainerInfo;
                if (info != null)
                {
                    desired.Add(info.Name);
                }
            }
            try
            {
                Loopback.SaveExemptions(desired);
                Reload();
                _status.Text = Strings.SavedMessage;
            }
            catch (Exception ex)
            {
                ShowError(ex);
            }
        }

        private void ShowError(Exception ex)
        {
            MessageBox.Show(
                this, ex.Message, Strings.ErrorTitle,
                MessageBoxButtons.OK, MessageBoxIcon.Error);
        }

        private static string DisplayText(AppContainerInfo info)
        {
            return string.IsNullOrEmpty(info.DisplayName) ? info.Name : info.DisplayName;
        }
    }
}
