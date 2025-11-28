namespace ATM_QR_scanner_simulator
{
    partial class frmMainATM
    {
        /// <summary>
        ///  Required designer variable.
        /// </summary>
        private System.ComponentModel.IContainer components = null;

        /// <summary>
        ///  Clean up any resources being used.
        /// </summary>
        /// <param name="disposing">true if managed resources should be disposed; otherwise, false.</param>
        protected override void Dispose(bool disposing)
        {
            if (disposing && (components != null))
            {
                components.Dispose();
            }
            base.Dispose(disposing);
        }

        #region Windows Form Designer generated code

        /// <summary>
        ///  Required method for Designer support - do not modify
        ///  the contents of this method with the code editor.
        /// </summary>
        private void InitializeComponent()
        {
            this.lblStatus = new System.Windows.Forms.Label();
            SuspendLayout();
            // lblStatus
            this.lblStatus.Location = new Point(10, 10);
            this.lblStatus.Name = "lblStatus";
            this.lblStatus.Size = new Size(400, 23);
            this.lblStatus.Text = "";
            // 
            // Form1
            // 
            AutoScaleDimensions = new SizeF(7F, 15F);
            AutoScaleMode = AutoScaleMode.Font;
            ClientSize = new Size(873, 475);
            Name = "frmMainATM";
            Text = "frmMainATM";
            ResumeLayout(false);
        }

        #endregion
    }
}
